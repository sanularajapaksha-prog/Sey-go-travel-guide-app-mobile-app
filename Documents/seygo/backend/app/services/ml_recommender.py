"""
ml_recommender.py
=================
Hybrid ML recommendation engine for SeyGo place recommendations.

Architecture:
  Stage 1 — Content-Based Model
      TF-IDF on (name + description + tags + category) → cosine similarity
      matrix.  One-hot category features.  Popularity score.

  Stage 2 — Collaborative Filtering (SVD)
      Truncated SVD on the user-place interaction matrix built from
      saved_destinations rows.  Predicts each user's affinity for every
      unseen place.

  Hybrid Scorer
      Weighted combination of content similarity, CF score, popularity, and
      distance decay. Weights auto-adjust when data is missing (cold-start,
      no location, etc.).

Model lifecycle:
  • Auto-trains on first call if no persisted model is found.
  • Artifacts saved to  <backend>/ml_models/  as joblib pickles.
  • Background retraining when the place catalogue changes by >10 %.
  • Call  MLRecommender.retrain(supabase)  explicitly to force a refresh.
"""

from __future__ import annotations

import json
import logging
import math
import os
import threading
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Optional

import numpy as np
from sklearn.decomposition import TruncatedSVD
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.preprocessing import MinMaxScaler

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

_BACKEND_DIR = Path(__file__).resolve().parent.parent.parent
ML_MODELS_DIR = _BACKEND_DIR / 'ml_models'
ML_MODELS_DIR.mkdir(exist_ok=True)

_CONTENT_MODEL_PATH = ML_MODELS_DIR / 'content_model.joblib'
_CF_MODEL_PATH = ML_MODELS_DIR / 'cf_model.joblib'
_PLACE_INDEX_PATH = ML_MODELS_DIR / 'place_index.joblib'
_META_PATH = ML_MODELS_DIR / 'model_meta.json'

# ---------------------------------------------------------------------------
# Hybrid weight defaults (overridable via environment variables)
# ---------------------------------------------------------------------------

_W_CONTENT = float(os.getenv('ML_W_CONTENT', '0.40'))
_W_CF = float(os.getenv('ML_W_CF', '0.30'))
_W_POPULARITY = float(os.getenv('ML_W_POPULARITY', '0.15'))
_W_DISTANCE = float(os.getenv('ML_W_DISTANCE', '0.15'))

# Minimum saved-destination interactions before CF kicks in
_CF_MIN_INTERACTIONS = int(os.getenv('ML_CF_MIN_INTERACTIONS', '5'))

# SVD latent factors
_SVD_N_COMPONENTS = int(os.getenv('ML_SVD_COMPONENTS', '20'))

# Gaussian sigma for distance decay (km)
_DISTANCE_SIGMA_KM = float(os.getenv('ML_DISTANCE_SIGMA_KM', '50.0'))


# ---------------------------------------------------------------------------
# Internal data structures
# ---------------------------------------------------------------------------

@dataclass
class _PlaceRecord:
    """Lightweight internal representation of a place row."""
    place_id: str
    name: str
    category: str
    tags: list[str]
    description: str
    latitude: float
    longitude: float
    avg_rating: float
    review_count: int
    taxonomy_category: str = ''
    taxonomy_group: str = ''
    google_url: Optional[str] = None
    photo_url: Optional[str] = None
    location: str = ''


@dataclass
class MLRecommendation:
    place_id: str
    name: str
    category: str
    tags: list[str]
    latitude: float
    longitude: float
    avg_rating: float
    review_count: int
    description: str
    taxonomy_category: str
    taxonomy_group: str
    google_url: Optional[str]
    photo_url: Optional[str]
    location: str
    distance_km: Optional[float]
    final_score: float
    score_breakdown: dict[str, float]
    reason: str
    cold_start: bool


@dataclass
class _ContentModel:
    vectorizer: TfidfVectorizer
    tfidf_matrix: Any          # sparse (N, vocab)
    popularity_scores: np.ndarray  # (N,) already normalised
    place_ids: list[str]


@dataclass
class _CFModel:
    svd: TruncatedSVD
    user_factors: np.ndarray       # (U, k)
    item_factors: np.ndarray       # (N, k)
    user_index: dict[str, int]     # user_id → row
    place_index: dict[str, int]    # place_id → col


@dataclass
class _ModelArtifacts:
    content: _ContentModel
    cf: Optional[_CFModel]
    places: list[_PlaceRecord]
    place_lookup: dict[str, _PlaceRecord]  # place_id → record
    trained_at: str
    num_places: int
    num_users: int


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    r = 6371.0
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlam = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlam / 2) ** 2
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def _safe_float(value, default: float = 0.0) -> float:
    if isinstance(value, (int, float)):
        return float(value)
    if isinstance(value, str):
        try:
            return float(value.strip())
        except ValueError:
            pass
    return default


def _parse_tags(value) -> list[str]:
    if value is None:
        return []
    if isinstance(value, list):
        return [str(t).strip() for t in value if str(t).strip()]
    if isinstance(value, str):
        text = value.strip()
        if not text:
            return []
        try:
            decoded = json.loads(text)
            if isinstance(decoded, list):
                return [str(t).strip() for t in decoded if str(t).strip()]
        except Exception:
            pass
        return [t.strip() for t in text.split(',') if t.strip()]
    return []


def _place_text(record: _PlaceRecord) -> str:
    """Combine all textual fields into a single string for TF-IDF."""
    parts: list[str] = [record.name]
    if record.category:
        parts.append(record.category)
    if record.taxonomy_category:
        parts.append(record.taxonomy_category)
    if record.taxonomy_group:
        parts.append(record.taxonomy_group)
    parts.extend(record.tags)
    if record.description:
        parts.append(record.description)
    if record.location:
        parts.append(record.location)
    return ' '.join(parts).lower()


def _normalise_array(arr: np.ndarray) -> np.ndarray:
    mn, mx = arr.min(), arr.max()
    if mx - mn < 1e-9:
        return np.zeros_like(arr, dtype=float)
    return (arr - mn) / (mx - mn)


def _popularity_raw(record: _PlaceRecord) -> float:
    """Bayesian-style popularity: rating × log(1 + review_count)."""
    return record.avg_rating * math.log1p(record.review_count)


def _build_reason(
    name: str,
    content: float,
    cf: float,
    pop: float,
    dist: Optional[float],
    cold_start: bool,
) -> str:
    parts: list[str] = []
    if not cold_start and cf >= 0.5:
        parts.append('Similar to places you saved')
    if content >= 0.3:
        parts.append('Matches your interests')
    if pop >= 0.6:
        parts.append(f'Highly rated')
    if dist is not None and dist <= 30:
        parts.append(f'{dist:.0f} km away')
    return ' · '.join(parts) if parts else 'Recommended for you'


# ---------------------------------------------------------------------------
# Model training
# ---------------------------------------------------------------------------

def _train_content_model(places: list[_PlaceRecord]) -> _ContentModel:
    logger.info('Training content model on %d places …', len(places))

    texts = [_place_text(p) for p in places]
    place_ids = [p.place_id for p in places]

    vectorizer = TfidfVectorizer(
        ngram_range=(1, 2),
        min_df=1,
        max_features=10_000,
        sublinear_tf=True,
    )
    tfidf_matrix = vectorizer.fit_transform(texts)

    raw_pop = np.array([_popularity_raw(p) for p in places], dtype=float)
    popularity_scores = _normalise_array(raw_pop)

    logger.info('Content model trained: vocab=%d, places=%d', len(vectorizer.vocabulary_), len(places))
    return _ContentModel(
        vectorizer=vectorizer,
        tfidf_matrix=tfidf_matrix,
        popularity_scores=popularity_scores,
        place_ids=place_ids,
    )


def _train_cf_model(
    places: list[_PlaceRecord],
    interactions: list[dict],  # list of {user_id, place_id}
) -> Optional[_CFModel]:
    """Train a Truncated SVD collaborative filtering model.

    Returns None if there is insufficient interaction data.
    """
    if len(interactions) < _CF_MIN_INTERACTIONS:
        logger.info('Not enough interactions (%d) for CF model.', len(interactions))
        return None

    # Build index maps
    user_ids = sorted({row['user_id'] for row in interactions})
    place_ids = [p.place_id for p in places]
    user_index = {uid: i for i, uid in enumerate(user_ids)}
    place_index_map = {pid: j for j, pid in enumerate(place_ids)}

    U = len(user_ids)
    N = len(place_ids)

    # Interaction matrix (U × N) — implicit feedback (1 = saved)
    matrix = np.zeros((U, N), dtype=np.float32)
    for row in interactions:
        ui = user_index.get(row['user_id'])
        pi = place_index_map.get(row['place_id'])
        if ui is not None and pi is not None:
            matrix[ui, pi] = 1.0

    n_components = min(_SVD_N_COMPONENTS, U - 1, N - 1)
    if n_components < 1:
        logger.info('Matrix too small for SVD (%dx%d).', U, N)
        return None

    svd = TruncatedSVD(n_components=n_components, random_state=42)
    user_factors = svd.fit_transform(matrix)        # (U, k)
    item_factors = svd.components_.T               # (N, k)

    logger.info(
        'CF model trained: %d users × %d places, %d latent factors',
        U, N, n_components,
    )
    return _CFModel(
        svd=svd,
        user_factors=user_factors,
        item_factors=item_factors,
        user_index=user_index,
        place_index=place_index_map,
    )


def _rows_to_place_records(place_rows: list[dict]) -> list[_PlaceRecord]:
    """Convert raw Supabase rows to _PlaceRecord objects."""
    from .place_taxonomy import infer_taxonomy  # avoid circular import at module level

    records: list[_PlaceRecord] = []
    for row in place_rows:
        lat = _safe_float(row.get('latitude') or row.get('lat'))
        lon = _safe_float(row.get('longitude') or row.get('lng') or row.get('lon'))
        if lat == 0.0 and lon == 0.0:
            continue  # skip rows with missing coords

        name = str(row.get('name') or row.get('place_name') or row.get('title') or '')
        category = str(
            row.get('primary_category')
            or row.get('category')
            or row.get('type')
            or row.get('primary_type')
            or ''
        )
        tags = _parse_tags(row.get('tags') or row.get('keywords') or row.get('labels'))
        description = str(
            row.get('description') or row.get('details') or row.get('summary') or ''
        )
        avg_rating = _safe_float(row.get('avg_rating') or row.get('rating'), 0.0)
        review_count = int(row.get('review_count') or row.get('reviews') or row.get('user_rating_count') or 0)
        location = str(
            row.get('location') or row.get('formatted_address') or row.get('address') or ''
        )

        tax_cat, tax_group = infer_taxonomy(name, category, tags, description)

        records.append(_PlaceRecord(
            place_id=str(row.get('place_id') or row.get('id') or ''),
            name=name,
            category=category,
            tags=tags,
            description=description,
            latitude=lat,
            longitude=lon,
            avg_rating=avg_rating,
            review_count=review_count,
            taxonomy_category=tax_cat,
            taxonomy_group=tax_group,
            google_url=str(row.get('google_url') or ''),
            photo_url=str(row.get('image_url') or row.get('photo_url') or ''),
            location=location,
        ))
    return records


def _fetch_interactions(supabase) -> list[dict]:
    """Fetch (user_id, place_id) pairs from saved_destinations."""
    try:
        resp = supabase.table('saved_destinations').select('user_id,google_place_id').execute()
        rows = resp.data or []
        return [
            {'user_id': str(r['user_id']), 'place_id': str(r['google_place_id'])}
            for r in rows
            if r.get('user_id') and r.get('google_place_id')
        ]
    except Exception as exc:
        logger.warning('Could not fetch saved_destinations: %s', exc)
        return []


def train(supabase) -> _ModelArtifacts:
    """Full training run.  Fetches data from Supabase, trains both models,
    persists artifacts, updates meta.json.
    """
    import joblib  # lazy import so startup is fast if joblib not installed

    logger.info('Starting ML model training …')

    # 1. Fetch data
    place_rows: list[dict] = []
    start, step = 0, 1000
    places_table = os.getenv('SUPABASE_PLACES_TABLE', 'places')
    while True:
        resp = supabase.table(places_table).select('*').range(start, start + step - 1).execute()
        batch = resp.data or []
        place_rows.extend(batch)
        if len(batch) < step:
            break
        start += step

    interactions = _fetch_interactions(supabase)

    # 2. Convert rows
    places = _rows_to_place_records(place_rows)
    if not places:
        raise ValueError('No usable place data found for training.')

    # 3. Train content model
    content_model = _train_content_model(places)

    # 4. Train CF model
    cf_model = _train_cf_model(places, interactions)

    # 5. Persist
    joblib.dump(content_model, _CONTENT_MODEL_PATH)
    if cf_model is not None:
        joblib.dump(cf_model, _CF_MODEL_PATH)
    joblib.dump(places, _PLACE_INDEX_PATH)

    trained_at = datetime.now(timezone.utc).isoformat()
    meta = {
        'trained_at': trained_at,
        'num_places': len(places),
        'num_users': len(cf_model.user_index) if cf_model else 0,
        'has_cf': cf_model is not None,
    }
    _META_PATH.write_text(json.dumps(meta, indent=2))
    logger.info('Training complete. %d places, %d users.', len(places), meta['num_users'])

    place_lookup = {p.place_id: p for p in places}
    return _ModelArtifacts(
        content=content_model,
        cf=cf_model,
        places=places,
        place_lookup=place_lookup,
        trained_at=trained_at,
        num_places=len(places),
        num_users=meta['num_users'],
    )


def _load_artifacts() -> Optional[_ModelArtifacts]:
    """Load persisted model artifacts from disk.  Returns None if missing."""
    try:
        import joblib

        if not (_CONTENT_MODEL_PATH.exists() and _PLACE_INDEX_PATH.exists() and _META_PATH.exists()):
            return None

        content_model: _ContentModel = joblib.load(_CONTENT_MODEL_PATH)
        places: list[_PlaceRecord] = joblib.load(_PLACE_INDEX_PATH)
        cf_model: Optional[_CFModel] = None
        if _CF_MODEL_PATH.exists():
            cf_model = joblib.load(_CF_MODEL_PATH)

        meta = json.loads(_META_PATH.read_text())
        place_lookup = {p.place_id: p for p in places}

        logger.info(
            'Loaded ML model artifacts (trained %s, %d places).',
            meta.get('trained_at', '?'),
            len(places),
        )
        return _ModelArtifacts(
            content=content_model,
            cf=cf_model,
            places=places,
            place_lookup=place_lookup,
            trained_at=meta.get('trained_at', ''),
            num_places=len(places),
            num_users=meta.get('num_users', 0),
        )
    except Exception as exc:
        logger.warning('Failed to load ML artifacts: %s', exc)
        return None


# ---------------------------------------------------------------------------
# Recommendation engine
# ---------------------------------------------------------------------------

class MLRecommender:
    """Thread-safe ML recommendation engine with lazy loading and background
    retraining.
    """

    def __init__(self) -> None:
        self._artifacts: Optional[_ModelArtifacts] = None
        self._lock = threading.Lock()
        self._training = False

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def retrain(self, supabase) -> None:
        """Force a synchronous retrain (blocks caller)."""
        with self._lock:
            self._artifacts = train(supabase)

    def ensure_ready(self, supabase) -> _ModelArtifacts:
        """Return loaded artifacts, training if necessary."""
        with self._lock:
            if self._artifacts is not None:
                return self._artifacts
            # Try loading from disk first (fast path)
            loaded = _load_artifacts()
            if loaded is not None:
                self._artifacts = loaded
                return self._artifacts
            # Cold boot — train synchronously
            logger.info('No cached model found. Training from scratch …')
            self._artifacts = train(supabase)
            return self._artifacts

    def maybe_retrain_async(self, supabase, current_place_count: int) -> None:
        """Trigger background retraining if the place catalogue has grown by
        more than 10 % since last training.
        """
        with self._lock:
            if self._training:
                return
            if self._artifacts is None:
                return
            drift = abs(current_place_count - self._artifacts.num_places)
            threshold = max(10, int(self._artifacts.num_places * 0.10))
            if drift < threshold:
                return
            self._training = True

        def _background_train():
            try:
                logger.info('Background retraining triggered (drift=%d) …', drift)
                new_artifacts = train(supabase)
                with self._lock:
                    self._artifacts = new_artifacts
            except Exception as exc:
                logger.exception('Background retraining failed: %s', exc)
            finally:
                with self._lock:
                    self._training = False

        t = threading.Thread(target=_background_train, daemon=True)
        t.start()

    def recommend(
        self,
        supabase,
        *,
        user_id: Optional[str] = None,
        query: Optional[str] = None,
        latitude: Optional[float] = None,
        longitude: Optional[float] = None,
        radius_km: Optional[float] = None,
        preferred_categories: Optional[list[str]] = None,
        top_n: int = 10,
    ) -> dict:
        """Generate hybrid ML recommendations.

        Returns a dict ready to be serialised as a JSON API response.
        """
        artifacts = self.ensure_ready(supabase)

        places = artifacts.places
        content_model = artifacts.content
        cf_model = artifacts.cf

        # ------------------------------------------------------------------
        # 1. Candidate filtering
        # ------------------------------------------------------------------
        candidates = list(places)

        if radius_km is not None and latitude is not None and longitude is not None:
            candidates = [
                p for p in candidates
                if _haversine_km(latitude, longitude, p.latitude, p.longitude) <= radius_km
            ]

        if preferred_categories:
            norm = {c.lower().strip() for c in preferred_categories}
            filtered = [
                p for p in candidates
                if p.category.lower() in norm
                or p.taxonomy_category.lower() in norm
                or p.taxonomy_group.lower() in norm
            ]
            # If filter is too aggressive, fall back to all candidates
            if filtered:
                candidates = filtered

        if not candidates:
            return self._empty_response(artifacts, user_id)

        n = len(candidates)
        candidate_ids = [p.place_id for p in candidates]

        # ------------------------------------------------------------------
        # 2. Content score — TF-IDF cosine similarity to query / tags
        # ------------------------------------------------------------------
        content_scores = np.zeros(n, dtype=float)
        if query and query.strip():
            query_vec = content_model.vectorizer.transform([query.lower()])
            # Map candidate place_ids back to rows in the full tfidf_matrix
            full_id_to_idx = {pid: i for i, pid in enumerate(content_model.place_ids)}
            candidate_row_indices = [full_id_to_idx[pid] for pid in candidate_ids if pid in full_id_to_idx]
            if candidate_row_indices:
                candidate_matrix = content_model.tfidf_matrix[candidate_row_indices]
                sims = cosine_similarity(query_vec, candidate_matrix).flatten()
                # Place sims back into content_scores (some candidates may not be in model)
                idx_ptr = 0
                for ci, pid in enumerate(candidate_ids):
                    if pid in full_id_to_idx:
                        content_scores[ci] = sims[idx_ptr]
                        idx_ptr += 1

        # ------------------------------------------------------------------
        # 3. CF score — predicted user affinity from SVD
        # ------------------------------------------------------------------
        cf_scores = np.zeros(n, dtype=float)
        cold_start = True
        user_interaction_count = 0

        if cf_model is not None and user_id is not None:
            ui = cf_model.user_index.get(user_id)
            if ui is not None:
                user_vec = artifacts.cf.user_factors[ui]  # (k,)
                user_interaction_count = int(np.count_nonzero(
                    artifacts.cf.svd.transform(
                        np.zeros((1, len(cf_model.place_index)), dtype=np.float32)
                    )
                ))
                for ci, pid in enumerate(candidate_ids):
                    pi = cf_model.place_index.get(pid)
                    if pi is not None:
                        cf_scores[ci] = float(np.dot(user_vec, cf_model.item_factors[pi]))
                cold_start = False

        cf_scores = _normalise_array(cf_scores)

        # ------------------------------------------------------------------
        # 4. Popularity score — from pre-computed content model
        # ------------------------------------------------------------------
        full_id_to_idx = {pid: i for i, pid in enumerate(content_model.place_ids)}
        pop_scores = np.array([
            content_model.popularity_scores[full_id_to_idx[pid]]
            if pid in full_id_to_idx else 0.0
            for pid in candidate_ids
        ], dtype=float)

        # ------------------------------------------------------------------
        # 5. Distance decay — Gaussian kernel
        # ------------------------------------------------------------------
        dist_scores = np.zeros(n, dtype=float)
        dist_km_values: list[Optional[float]] = [None] * n
        if latitude is not None and longitude is not None:
            for ci, p in enumerate(candidates):
                d = _haversine_km(latitude, longitude, p.latitude, p.longitude)
                dist_km_values[ci] = round(d, 2)
                dist_scores[ci] = math.exp(-0.5 * (d / _DISTANCE_SIGMA_KM) ** 2)

        # ------------------------------------------------------------------
        # 6. Dynamic weight adjustment
        # ------------------------------------------------------------------
        w_content = _W_CONTENT if (query and query.strip()) else 0.0
        w_cf = _W_CF if not cold_start else 0.0
        w_pop = _W_POPULARITY
        w_dist = _W_DISTANCE if latitude is not None else 0.0

        weight_sum = w_content + w_cf + w_pop + w_dist
        if weight_sum < 1e-9:
            weight_sum = 1.0

        final_scores = (
            w_content * content_scores
            + w_cf * cf_scores
            + w_pop * pop_scores
            + w_dist * dist_scores
        ) / weight_sum

        # ------------------------------------------------------------------
        # 7. Rank and return top-N
        # ------------------------------------------------------------------
        ranked_indices = np.argsort(final_scores)[::-1][:top_n]

        recommendations: list[dict] = []
        for ci in ranked_indices:
            p = candidates[ci]
            dist = dist_km_values[ci]
            cs = float(content_scores[ci])
            cfs = float(cf_scores[ci])
            ps = float(pop_scores[ci])
            ds = float(dist_scores[ci])
            fs = float(final_scores[ci])

            reason = _build_reason(p.name, cs, cfs, ps, dist, cold_start)

            recommendations.append({
                'place': {
                    'place_id': p.place_id,
                    'name': p.name,
                    'category': p.category,
                    'tags': p.tags,
                    'latitude': p.latitude,
                    'longitude': p.longitude,
                    'avg_rating': p.avg_rating,
                    'review_count': p.review_count,
                    'description': p.description,
                    'taxonomy_category': p.taxonomy_category,
                    'taxonomy_group': p.taxonomy_group,
                    'google_url': p.google_url or None,
                    'photo_url': p.photo_url or None,
                    'location': p.location,
                },
                'score': round(fs, 4),
                'score_breakdown': {
                    'content': round(cs, 4),
                    'collaborative': round(cfs, 4),
                    'popularity': round(ps, 4),
                    'distance': round(ds, 4),
                },
                'distance_km': dist,
                'reason': reason,
                'cold_start': cold_start,
            })

        # Trigger background retraining if catalogue has drifted
        self.maybe_retrain_async(supabase, len(places))

        return {
            'user_id': user_id,
            'count': len(recommendations),
            'model_version': artifacts.trained_at[:10] if artifacts.trained_at else 'unknown',
            'cold_start': cold_start,
            'recommendations': recommendations,
        }

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    def model_info(self) -> dict:
        """Return metadata about the currently loaded model."""
        if self._artifacts is None:
            loaded = _load_artifacts()
            if loaded:
                with self._lock:
                    self._artifacts = loaded
        if self._artifacts is None:
            return {'status': 'not_trained'}
        return {
            'status': 'ready',
            'trained_at': self._artifacts.trained_at,
            'num_places': self._artifacts.num_places,
            'num_users': self._artifacts.num_users,
            'has_cf_model': self._artifacts.cf is not None,
            'model_dir': str(ML_MODELS_DIR),
        }

    @staticmethod
    def _empty_response(artifacts: _ModelArtifacts, user_id: Optional[str]) -> dict:
        return {
            'user_id': user_id,
            'count': 0,
            'model_version': artifacts.trained_at[:10] if artifacts.trained_at else 'unknown',
            'cold_start': True,
            'recommendations': [],
        }
