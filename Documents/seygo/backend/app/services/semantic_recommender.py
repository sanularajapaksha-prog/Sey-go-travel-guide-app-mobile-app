"""
semantic_recommender.py
=======================
High-accuracy semantic search engine for SeyGo.

Architecture:
  • sentence-transformers (paraphrase-multilingual-MiniLM-L12-v2)
      - 50+ languages: English, Sinhala romanized, Tamil romanized
      - 384-dim L2-normalised embeddings (~118 MB model, ~7 MB index)
      - dot-product search == cosine similarity after normalisation

  • Intent Parser
      - Extracts location hint + category hint from any free-text query
      - Sri Lankan keyword dictionary (EN + Sinhala + Tamil)

  • Geocoder
      - Google Maps Geocoding API (primary, uses existing API key)
      - Nominatim / OSM (free fallback, no key needed)

  • Ranking pipeline per result:
        final = (semantic × 0.55) + (distance_weight × 0.25) + (rating × 0.10)
                × category_boost (×1.4 if detected category matches)

  • Fallback chain:
        1. radius filter → 2. expand radius ×3 → 3. pure semantic (no radius)

  • Auto-persists index to disk (ml_models/semantic_*.npy / .json).
    Rebuilds in background when place count drifts >10 %.
"""

from __future__ import annotations

import json
import logging
import math
import os
import re
import threading
from pathlib import Path
from typing import Optional

import numpy as np

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
_BACKEND_DIR = Path(__file__).resolve().parent.parent.parent
_MODELS_DIR = _BACKEND_DIR / 'ml_models'
_MODELS_DIR.mkdir(exist_ok=True)

_VECTORS_PATH = _MODELS_DIR / 'semantic_vectors.npy'
_PLACES_PATH  = _MODELS_DIR / 'semantic_places.json'

# Model — multilingual MiniLM handles EN/Sinhala/Tamil
# Override via SEMANTIC_MODEL env var to swap in a higher-accuracy model without code changes
_MODEL_NAME = os.getenv('SEMANTIC_MODEL', 'paraphrase-multilingual-MiniLM-L12-v2')

# Minimum number of places that must change before a background rebuild is triggered
_REBUILD_DRIFT_THRESHOLD_PCT = 0.10  # 10% of index size

# ---------------------------------------------------------------------------
# Intent keywords  (English + Sinhala romanised + Tamil romanised)
# ---------------------------------------------------------------------------
CATEGORY_KEYWORDS: dict[str, list[str]] = {
    'Cafe': [
        'cafe', 'coffee', 'bakery', 'pastry', 'espresso', 'cappuccino',
        'කෝපි', 'තේ කඩ', 'tea shop', 'kafe', 'kopi',
    ],
    'Restaurant': [
        'restaurant', 'food', 'eat', 'lunch', 'dinner', 'breakfast',
        'rice', 'kottu', 'meal', 'dining', 'curry', 'biryani', 'bbq',
        'கடை', 'உணவு', 'කෑම', 'ආහාර', 'bhojana', 'rotti',
    ],
    'Temple': [
        'temple', 'kovil', 'church', 'mosque', 'devalaya', 'dagoba',
        'stupa', 'vihara', 'viharaya', 'bo tree', 'shrine', 'kataragama',
        'පන්සල', 'කෝවිල', 'දේවාලය', 'கோவில்', 'கோயில்', 'masjid',
        'basilica', 'cathedral', 'chapel', 'pagoda',
    ],
    'Garden': [
        'garden', 'park', 'botanical', 'flowers', 'udyana', 'uyana',
        'playground', 'recreation', 'greenery', 'arboretum',
        'උද්‍යාන', 'ගොවිතැන', 'vanodyana',
    ],
    'Historical': [
        'historical', 'ancient', 'ruins', 'fort', 'heritage', 'museum',
        'archaeological', 'old city', 'kingdom', 'palace', 'citadel',
        'puraanika', 'ithihasika', 'anuradhapura', 'polonnaruwa',
        'sigiriya', 'dambulla', 'yapahuwa', 'panduwasnuwara',
    ],
    'Beach': [
        'beach', 'sea', 'coast', 'surf', 'swim', 'ocean', 'shore',
        'snorkel', 'diving', 'lagoon', 'bay',
        'වෙරළ', 'கடற்கரை', 'kadal', 'thurai',
    ],
    'Nature': [
        'waterfall', 'wildlife', 'safari', 'national park', 'jungle',
        'forest', 'nature', 'bird', 'elephant', 'ella', 'falls',
        'nuwara', 'hill', 'mountain', 'peak', 'viewpoint', 'scenic',
        'horton', 'knuckles', 'sinharaja', 'yala', 'udawalawe',
        'uyanan', 'uda', 'diyalumaella',
    ],
    'Accommodation': [
        'hotel', 'resort', 'hostel', 'stay', 'guesthouse', 'lodge',
        'rest house', 'bungalow', 'villa', 'inn', 'homestay',
    ],
    'Shopping': [
        'shop', 'market', 'mall', 'bazaar', 'boutique', 'store',
        'fair', 'pola', 'pettah', 'supermarket', 'outlet',
    ],
    'Adventure': [
        'surf', 'dive', 'snorkel', 'climb', 'hike', 'zip line',
        'rafting', 'kayak', 'cycling', 'trekking', 'paragliding',
        'camping', 'abseiling',
    ],
    'Spa': [
        'spa', 'massage', 'ayurveda', 'wellness', 'yoga', 'meditation',
        'retreat', 'relaxation', 'hot spring',
    ],
}

# All recognised Sri Lanka place names (longest first → greedy match)
_SL_PLACES: list[str] = sorted([
    'Colombo', 'Gampaha', 'Kalutara', 'Kandy', 'Matale', 'Nuwara Eliya',
    'Galle', 'Matara', 'Hambantota', 'Jaffna', 'Kilinochchi', 'Mannar',
    'Vavuniya', 'Batticaloa', 'Ampara', 'Trincomalee', 'Kurunegala',
    'Puttalam', 'Anuradhapura', 'Polonnaruwa', 'Badulla', 'Monaragala',
    'Ratnapura', 'Kegalle', 'Ella', 'Mirissa', 'Unawatuna', 'Hikkaduwa',
    'Bentota', 'Negombo', 'Sigiriya', 'Dambulla', 'Habarana',
    'Yakkala', 'Gampola', 'Avissawella', 'Horana', 'Panadura',
    'Moratuwa', 'Dehiwala', 'Nugegoda', 'Maharagama', 'Kaduwela',
    'Kelaniya', 'Wattala', 'Ja-Ela', 'Minuwangoda', 'Veyangoda',
    'Nittambuwa', 'Kadawatha', 'Ragama', 'Piliyandala', 'Homagama',
    'Malabe', 'Battaramulla', 'Rajagiriya', 'Thalawathugoda',
    'Wadduwa', 'Aluthgama', 'Beruwala', 'Chilaw', 'Kalpitiya',
    'Arugam Bay', 'Pasikuda', 'Nilaveli', 'Uppuveli',
    'Horton Plains', 'Knuckles', 'Kitulgala', 'Sinharaja',
    'Uda Walawe', 'Yala', 'Bundala', 'Tissamaharama', 'Kataragama',
    'Tangalle', 'Weligama', 'Dickwella', 'Dondra', 'Galle Fort',
    'Koggala', 'Ahangama', 'Ambalangoda', 'Balapitiya',
    'Mawanella', 'Warakapola', 'Rambukkana', 'Hatton',
    'Talawakele', 'Ginigathena', 'Kalmunai', 'Akkaraipattu',
    'Kantale', 'Muttur', 'Pettah', 'Fort', 'Borella',
    'Cinnamon Gardens', 'Wellawatte', 'Bambalapitiya',
    'Ethul Kotte', 'Koswatta', 'Pittugala', 'Minneriya',
    'Sigiriya Rock', 'Pidurangala', 'Ritigala', 'Mihintale',
    'Adam\'s Peak', 'Sri Pada', 'Knuckles Range',
], key=len, reverse=True)


# ---------------------------------------------------------------------------
# Intent parser
# ---------------------------------------------------------------------------

def parse_intent(query: str) -> dict:
    """
    Extract from a free-text query:
      - detected_category  (e.g. 'Temple', 'Cafe', …)
      - detected_location  (e.g. 'Kandy', 'Yakkala', …)
      - radius_km          (if user typed "5 km", "10km", …)
    """
    text_lower = query.strip().lower()

    # Category detection — first match wins
    detected_category: Optional[str] = None
    for cat, keywords in CATEGORY_KEYWORDS.items():
        if any(kw in text_lower for kw in keywords):
            detected_category = cat
            break

    # Radius detection
    m = re.search(r'(\d+(?:\.\d+)?)\s*km', text_lower)
    radius_km: Optional[float] = float(m.group(1)) if m else None

    # Location detection — longest name first to avoid partial matches
    detected_location: Optional[str] = None
    for place in _SL_PLACES:
        if place.lower() in text_lower:
            detected_location = place
            break

    return {
        'detected_category': detected_category,
        'detected_location': detected_location,
        'radius_km': radius_km,
    }


# ---------------------------------------------------------------------------
# Geocoder
# ---------------------------------------------------------------------------

def geocode_location(location: str) -> Optional[tuple[float, float]]:
    """Convert a Sri Lankan place name to (lat, lng)."""
    api_key = os.getenv('GOOGLE_MAPS_API_KEY', '').strip()
    if api_key:
        result = _geocode_google(location, api_key)
        if result:
            return result
    return _geocode_nominatim(location)


def _geocode_google(location: str, api_key: str) -> Optional[tuple[float, float]]:
    import httpx
    try:
        resp = httpx.get(
            'https://maps.googleapis.com/maps/api/geocode/json',
            params={
                'address': f'{location}, Sri Lanka',
                'key': api_key,
                'region': 'lk',
                'components': 'country:LK',
            },
            timeout=8.0,
        )
        data = resp.json()
        if data.get('status') == 'OK' and data.get('results'):
            loc = data['results'][0]['geometry']['location']
            return float(loc['lat']), float(loc['lng'])
    except Exception as exc:
        logger.warning('Google geocode failed for "%s": %s', location, exc)
    return None


def _geocode_nominatim(location: str) -> Optional[tuple[float, float]]:
    import httpx
    try:
        resp = httpx.get(
            'https://nominatim.openstreetmap.org/search',
            params={'q': f'{location}, Sri Lanka', 'format': 'json', 'limit': 1},
            headers={'User-Agent': 'SeyGoTravelApp/1.0'},
            timeout=8.0,
        )
        results = resp.json()
        if results:
            return float(results[0]['lat']), float(results[0]['lon'])
    except Exception as exc:
        logger.warning('Nominatim geocode failed for "%s": %s', location, exc)
    return None


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371.0
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (math.sin(dlat / 2) ** 2
         + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2))
         * math.sin(dlon / 2) ** 2)
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def _build_place_text(place: dict) -> str:
    """Combine all textual fields into one string for embedding."""
    fields = [
        place.get('name') or '',
        place.get('description') or '',
        place.get('primary_category') or place.get('category') or '',
        place.get('tags') or '',
        place.get('location') or '',
        place.get('seed_area') or '',
        place.get('taxonomy_category') or '',
        place.get('taxonomy_group') or '',
        place.get('keywords') or '',
    ]
    if isinstance(fields[3], list):
        fields[3] = ' '.join(fields[3])
    return ' '.join(str(f) for f in fields if f).strip()


def _safe_float(value, default: float = 0.0) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


# ---------------------------------------------------------------------------
# Core engine
# ---------------------------------------------------------------------------

class SemanticRecommender:
    """
    Thread-safe semantic search engine.

    Lifecycle:
      1. ensure_ready(supabase) — called at startup; loads from disk or builds index.
      2. search(...)            — fast query; no Supabase call needed after warmup.
      3. rebuild(supabase)      — force full re-index (e.g. after bulk place import).
    """

    def __init__(self) -> None:
        self._model = None                   # SentenceTransformer (lazy)
        self._vectors: Optional[np.ndarray] = None  # (N, 384) float32, L2-normed
        self._places: list[dict] = []
        self._lock = threading.RLock()
        self._ready = False
        self._num_at_build = 0

    # ------------------------------------------------------------------
    # Public
    # ------------------------------------------------------------------

    def ensure_ready(self, supabase) -> None:
        with self._lock:
            if self._ready:
                return
            if self._load_from_disk():
                self._ready = True
                logger.info('Semantic index loaded from disk (%d places).', len(self._places))
                return
            logger.info('Building semantic index from Supabase...')
            self._build_index(supabase)
            self._ready = True

    def rebuild(self, supabase) -> dict:
        """Force full rebuild. Blocks until complete."""
        with self._lock:
            self._build_index(supabase)
            self._ready = True
        return {
            'status': 'rebuilt',
            'num_places': len(self._places),
            'vector_shape': list(self._vectors.shape) if self._vectors is not None else [],
        }

    def search(
        self,
        supabase,
        *,
        query: str,
        center_lat: Optional[float] = None,
        center_lng: Optional[float] = None,
        radius_km: float = 10.0,
        top_n: int = 20,
        detected_category: Optional[str] = None,
    ) -> list[dict]:
        """
        Full search pipeline:
          1. Encode query → 384-dim vector
          2. Cosine similarity against all place vectors
          3. Radius filter (haversine)
          4. Score = semantic×0.55 + distance×0.25 + rating×0.10 × category_boost
          5. Sort + return top_n
        """
        self.ensure_ready(supabase)

        if not self._places:
            return []

        model = self._get_model()

        # ── Keyword fallback when sentence_transformers is unavailable ──
        if model is None or self._vectors is None:
            return self._keyword_search(
                query=query,
                center_lat=center_lat,
                center_lng=center_lng,
                radius_km=radius_km,
                top_n=top_n,
                detected_category=detected_category,
            )

        query_vec = model.encode(
            [query],
            convert_to_numpy=True,
            normalize_embeddings=True,
        )  # (1, 384)

        # Cosine similarity: vectors are L2-normed → dot product = cosine sim
        sims = np.dot(self._vectors, query_vec.T).flatten()  # (N,)

        results: list[dict] = []
        for i, place in enumerate(self._places):
            lat = place.get('_lat')
            lng = place.get('_lng')

            # ── Geographic filter ──────────────────────────────────────
            if center_lat is not None and center_lng is not None:
                # Need coords to do radius filtering — skip coord-less places
                if lat is None or lng is None:
                    continue
                dist_km = _haversine_km(center_lat, center_lng, lat, lng)
                if dist_km > radius_km:
                    continue
            else:
                dist_km = None

            semantic = float(sims[i])

            # ── Distance weight: 1.0 at center → 0.6 at edge ──────────
            if dist_km is not None and radius_km > 0:
                dist_weight = 1.0 - (dist_km / radius_km) * 0.4
            else:
                dist_weight = 1.0

            # ── Category boost ×1.4 ────────────────────────────────────
            boost = 1.0
            if detected_category:
                pc  = (place.get('primary_category') or place.get('category') or '').lower()
                tc  = (place.get('taxonomy_category') or '').lower()
                tg  = (place.get('taxonomy_group') or '').lower()
                det = detected_category.lower()
                if det in pc or det in tc or det in tg or pc in det:
                    boost = 1.4

            # ── Rating score (Bayesian-style, normalised to 0-1) ───────
            rating   = _safe_float(place.get('avg_rating') or place.get('rating'), 3.0)
            reviews  = int(_safe_float(place.get('review_count') or place.get('reviews'), 0))
            rating_s = (min(rating, 5.0) / 5.0) * math.log1p(reviews + 1) / math.log1p(1001)

            # ── Final score ────────────────────────────────────────────
            final = (semantic * 0.55 + dist_weight * 0.25 + rating_s * 0.10) * boost

            results.append({
                **place,
                '_score':            round(final, 4),
                '_semantic':         round(semantic, 4),
                '_dist_km':          round(dist_km, 2) if dist_km is not None else None,
                '_category_boosted': boost > 1.0,
            })

        results.sort(key=lambda x: x['_score'], reverse=True)

        # Trigger background rebuild if catalogue has drifted
        self._maybe_rebuild_async(supabase)

        return results[:top_n]

    def index_info(self) -> dict:
        return {
            'ready':      self._ready,
            'num_places': len(self._places),
            'model':      _MODEL_NAME,
            'vector_dim': int(self._vectors.shape[1]) if self._vectors is not None else 0,
            'index_path': str(_VECTORS_PATH),
        }

    def _keyword_search(self, *, query, center_lat, center_lng, radius_km, top_n, detected_category):
        """Keyword-based fallback when sentence_transformers is not installed."""
        keywords = [w.lower() for w in query.split() if len(w) > 2]
        results = []
        for place in self._places:
            text = ' '.join(filter(None, [
                place.get('name', ''),
                place.get('primary_category', ''),
                place.get('address', ''),
                place.get('seed_area', ''),
            ])).lower()

            lat = place.get('_lat')
            lng = place.get('_lng')

            if center_lat is not None and center_lng is not None:
                if lat is None or lng is None:
                    continue
                dist_km = _haversine_km(center_lat, center_lng, lat, lng)
                if dist_km > radius_km:
                    continue
            else:
                dist_km = None

            keyword_score = sum(1 for kw in keywords if kw in text) / max(len(keywords), 1)

            boost = 1.0
            if detected_category:
                pc = (place.get('primary_category') or '').lower()
                if detected_category.lower() in pc or pc in detected_category.lower():
                    boost = 1.4

            rating = _safe_float(place.get('avg_rating'), 3.0)
            rating_s = min(rating, 5.0) / 5.0

            score = (keyword_score * 0.6 + rating_s * 0.2) * boost
            results.append({**place, '_score': round(score, 4), '_dist_km': round(dist_km, 2) if dist_km else None})

        results.sort(key=lambda x: x['_score'], reverse=True)
        return results[:top_n]

    # ------------------------------------------------------------------
    # Internals
    # ------------------------------------------------------------------

    def _get_model(self):
        if self._model is None:
            try:
                logger.info('Loading sentence-transformer: %s', _MODEL_NAME)
                from sentence_transformers import SentenceTransformer
                self._model = SentenceTransformer(_MODEL_NAME)
                logger.info('Model ready.')
            except ModuleNotFoundError:
                logger.warning(
                    'sentence_transformers not installed — '
                    'semantic search will fall back to keyword matching. '
                    'Run: pip install sentence-transformers'
                )
                self._model = 'unavailable'
        return None if self._model == 'unavailable' else self._model

    def _fetch_all_places(self, supabase) -> list[dict]:
        table = os.getenv('SUPABASE_PLACES_TABLE', 'tourist_places')
        rows: list[dict] = []
        offset, step = 0, 1000
        while True:
            batch = (
                supabase.table(table)
                .select('*')
                .range(offset, offset + step - 1)
                .execute()
                .data or []
            )
            rows.extend(batch)
            if len(batch) < step:
                break
            offset += step
        logger.info('Fetched %d rows from Supabase table "%s".', len(rows), table)
        return rows

    def _build_index(self, supabase) -> None:
        from .place_taxonomy import infer_taxonomy

        rows = self._fetch_all_places(supabase)

        places: list[dict] = []
        for row in rows:
            # Extract lat / lng
            lat = lng = None
            for k in ('latitude', 'lat'):
                try:
                    v = row.get(k)
                    if v is not None:
                        lat = float(v); break
                except (TypeError, ValueError):
                    pass
            for k in ('longitude', 'lng', 'lon'):
                try:
                    v = row.get(k)
                    if v is not None:
                        lng = float(v); break
                except (TypeError, ValueError):
                    pass

            # Validate Sri Lanka bounding box (only if coords exist)
            if lat is not None and lng is not None:
                if not (5.5 <= lat <= 10.1 and 79.4 <= lng <= 82.1):
                    continue

            # Infer taxonomy
            name     = str(row.get('name') or '')
            category = str(row.get('primary_category') or row.get('category') or '')
            raw_tags = row.get('tags') or ''
            if isinstance(raw_tags, list):
                tags = [str(t) for t in raw_tags]
            elif isinstance(raw_tags, str) and raw_tags.strip():
                try:
                    decoded = json.loads(raw_tags)
                    tags = [str(t) for t in decoded] if isinstance(decoded, list) else [raw_tags]
                except Exception:
                    tags = [t.strip() for t in raw_tags.split(',') if t.strip()]
            else:
                tags = []
            desc = str(row.get('description') or '')
            tax_cat, tax_group = infer_taxonomy(name, category, tags, desc)

            p = dict(row)
            p['_lat']             = lat
            p['_lng']             = lng
            p['taxonomy_category'] = tax_cat
            p['taxonomy_group']   = tax_group
            places.append(p)

        if not places:
            logger.error('No valid places found for semantic index.')
            return

        logger.info('Encoding %d places with %s ...', len(places), _MODEL_NAME)
        model = self._get_model()
        texts   = [_build_place_text(p) for p in places]
        vectors = model.encode(
            texts,
            batch_size=128,
            show_progress_bar=False,
            convert_to_numpy=True,
            normalize_embeddings=True,
        ).astype(np.float32)

        self._places        = places
        self._vectors       = vectors
        self._num_at_build  = len(places)

        # Persist
        try:
            np.save(str(_VECTORS_PATH), vectors)
            with open(str(_PLACES_PATH), 'w', encoding='utf-8') as f:
                json.dump(places, f, ensure_ascii=False, default=str)
            logger.info(
                'Semantic index saved: %d places, vectors %s.',
                len(places), vectors.shape,
            )
        except Exception as exc:
            logger.warning('Could not save semantic index to disk: %s', exc)

    def _load_from_disk(self) -> bool:
        try:
            if not (_VECTORS_PATH.exists() and _PLACES_PATH.exists()):
                return False
            vectors = np.load(str(_VECTORS_PATH)).astype(np.float32)
            with open(str(_PLACES_PATH), 'r', encoding='utf-8') as f:
                places = json.load(f)
            self._vectors      = vectors
            self._places       = places
            self._num_at_build = len(places)
            return True
        except Exception as exc:
            logger.warning('Failed to load semantic index from disk: %s', exc)
            return False

    def _maybe_rebuild_async(self, supabase) -> None:
        if not self._ready or not self._places:
            return
        drift     = abs(len(self._places) - self._num_at_build)
        threshold = max(50, int(self._num_at_build * 0.10))
        if drift < threshold:
            return

        def _bg():
            try:
                logger.info('Background semantic rebuild (drift=%d) ...', drift)
                with self._lock:
                    self._build_index(supabase)
            except Exception as exc:
                logger.exception('Background rebuild failed: %s', exc)

        threading.Thread(target=_bg, daemon=True).start()


# Module-level singleton shared across all FastAPI requests
semantic_recommender = SemanticRecommender()
