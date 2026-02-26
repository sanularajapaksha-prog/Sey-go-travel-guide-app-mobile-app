import math
import os
from dataclasses import dataclass
from typing import Optional

import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

from ..schemas.recommendation import ScoredPlace
from .place_taxonomy import normalize_category_name

W_CONTENT = float(os.getenv('W_CONTENT', '0.35'))
W_KEYWORD = float(os.getenv('W_KEYWORD', '0.25'))
W_POPULARITY = float(os.getenv('W_POPULARITY', '0.20'))
W_DISTANCE = float(os.getenv('W_DISTANCE', '0.20'))
W_TAXONOMY = float(os.getenv('W_TAXONOMY', '0.35'))


@dataclass
class PlaceFeature:
    place_id: str
    name: str
    category: str
    tags: list[str]
    latitude: float
    longitude: float
    avg_rating: float
    review_count: int
    description: Optional[str] = None
    taxonomy_category: str = 'Viewpoints / scenic spots'
    taxonomy_group: str = 'Nature & Outdoor'


def _haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    r = 6371.0
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlam = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlam / 2) ** 2
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def _normalize(values: np.ndarray) -> np.ndarray:
    min_v = values.min()
    max_v = values.max()
    if max_v - min_v == 0:
        return np.zeros_like(values)
    return (values - min_v) / (max_v - min_v)


def _place_to_text(place: PlaceFeature) -> str:
    parts = [place.category] + place.tags
    if place.description:
        parts.append(place.description)
    return ' '.join(parts).lower()


class PlaceRecommender:
    def recommend(
        self,
        places: list[PlaceFeature],
        preference_tags: list[str],
        selected_categories: list[str],
        selected_group: Optional[str],
        latitude: Optional[float],
        longitude: Optional[float],
        search_keyword: Optional[str],
        radius_km: float,
        top_n: int,
    ) -> list[ScoredPlace]:
        if not places:
            return []

        candidates = self._filter_by_radius(places, latitude, longitude, radius_km)
        if not candidates:
            return []
        candidates = self._filter_by_category(candidates, selected_categories, selected_group)
        if not candidates:
            return []

        content_scores = self._content_scores(preference_tags, candidates)
        keyword_scores = self._keyword_scores(search_keyword, candidates)
        taxonomy_scores = self._taxonomy_scores(selected_categories, selected_group, candidates)
        popularity_scores = self._popularity_scores(candidates)
        distance_scores = self._distance_scores(candidates, latitude, longitude)

        w_content = W_CONTENT if preference_tags else 0.0
        w_keyword = W_KEYWORD if search_keyword else 0.0
        w_taxonomy = W_TAXONOMY if selected_categories or selected_group else 0.0
        w_popularity = W_POPULARITY
        w_distance = W_DISTANCE if latitude is not None and longitude is not None else 0.0
        weight_sum = w_content + w_keyword + w_taxonomy + w_popularity + w_distance
        if weight_sum == 0:
            weight_sum = 1.0

        final_scores = (
            w_content * content_scores
            + w_keyword * keyword_scores
            + w_taxonomy * taxonomy_scores
            + w_popularity * popularity_scores
            + w_distance * distance_scores
        ) / weight_sum
        ranked_idx = np.argsort(final_scores)[::-1][:top_n]

        results: list[ScoredPlace] = []
        for i in ranked_idx:
            place = candidates[i]
            dist_km = None
            if latitude is not None and longitude is not None:
                dist_km = _haversine_km(latitude, longitude, place.latitude, place.longitude)

            results.append(
                ScoredPlace(
                    place_id=place.place_id,
                    name=place.name,
                    category=place.category,
                    tags=place.tags,
                    latitude=place.latitude,
                    longitude=place.longitude,
                    avg_rating=place.avg_rating,
                    review_count=place.review_count,
                    description=place.description,
                    taxonomy_category=place.taxonomy_category,
                    taxonomy_group=place.taxonomy_group,
                    distance_km=round(dist_km, 2) if dist_km is not None else None,
                    final_score=round(float(final_scores[i]), 4),
                    content_score=round(float(content_scores[i]), 4),
                    keyword_score=round(float(keyword_scores[i]), 4),
                    taxonomy_score=round(float(taxonomy_scores[i]), 4),
                    popularity_score=round(float(popularity_scores[i]), 4),
                    distance_score=round(float(distance_scores[i]), 4),
                )
            )
        return results

    def _filter_by_radius(
        self,
        places: list[PlaceFeature],
        lat: Optional[float],
        lon: Optional[float],
        radius_km: float,
    ) -> list[PlaceFeature]:
        if lat is None or lon is None:
            return places
        return [p for p in places if _haversine_km(lat, lon, p.latitude, p.longitude) <= radius_km]

    def _filter_by_category(
        self,
        places: list[PlaceFeature],
        selected_categories: list[str],
        selected_group: Optional[str],
    ) -> list[PlaceFeature]:
        if not selected_categories and not selected_group:
            return places

        normalized_categories = {normalize_category_name(category).lower() for category in selected_categories}
        normalized_group = selected_group.lower().strip() if selected_group else None
        filtered: list[PlaceFeature] = []
        for place in places:
            category_match = place.taxonomy_category.lower() in normalized_categories if normalized_categories else False
            group_match = place.taxonomy_group.lower() == normalized_group if normalized_group else False
            if category_match or group_match:
                filtered.append(place)
        return filtered

    def _content_scores(self, user_tags: list[str], places: list[PlaceFeature]) -> np.ndarray:
        if not user_tags:
            return np.zeros(len(places))

        user_text = ' '.join(user_tags).lower()
        place_texts = [_place_to_text(p) for p in places]
        all_texts = [user_text] + place_texts

        vectorizer = TfidfVectorizer(ngram_range=(1, 2), min_df=1)
        matrix = vectorizer.fit_transform(all_texts)
        user_vec = matrix[0]
        place_vecs = matrix[1:]
        scores = cosine_similarity(user_vec, place_vecs).flatten()
        return _normalize(scores)

    def _keyword_scores(self, keyword: Optional[str], places: list[PlaceFeature]) -> np.ndarray:
        if not keyword:
            return np.zeros(len(places))
        kw = keyword.lower().strip()
        scores = np.zeros(len(places))

        for i, place in enumerate(places):
            score = 0.0
            if place.category.lower() == kw:
                score += 1.0
            if kw in [t.lower() for t in place.tags]:
                score += 0.7
            if kw in place.name.lower():
                score += 0.4
            if place.description and kw in place.description.lower():
                score += 0.2
            scores[i] = min(score, 1.0)
        return scores

    def _taxonomy_scores(
        self,
        selected_categories: list[str],
        selected_group: Optional[str],
        places: list[PlaceFeature],
    ) -> np.ndarray:
        if not selected_categories and not selected_group:
            return np.zeros(len(places))

        normalized_categories = {normalize_category_name(category).lower() for category in selected_categories}
        normalized_group = selected_group.lower().strip() if selected_group else None
        scores = np.zeros(len(places))
        for i, place in enumerate(places):
            score = 0.0
            if normalized_group and place.taxonomy_group.lower() == normalized_group:
                score += 0.6
            if normalized_categories and place.taxonomy_category.lower() in normalized_categories:
                score += 1.0
            scores[i] = min(score, 1.0)
        return scores

    def _popularity_scores(self, places: list[PlaceFeature]) -> np.ndarray:
        raw = np.array([p.avg_rating * math.log1p(p.review_count) for p in places])
        return _normalize(raw)

    def _distance_scores(
        self,
        places: list[PlaceFeature],
        lat: Optional[float],
        lon: Optional[float],
    ) -> np.ndarray:
        if lat is None or lon is None:
            return np.zeros(len(places))
        scores = np.array([1.0 / (1.0 + _haversine_km(lat, lon, p.latitude, p.longitude)) for p in places])
        return _normalize(scores)
