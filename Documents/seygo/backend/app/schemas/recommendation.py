from typing import Optional

from pydantic import BaseModel, Field


class PlaceRecommendationRequest(BaseModel):
    preference_tags: list[str] = Field(default_factory=list)
    selected_categories: list[str] = Field(default_factory=list)
    selected_group: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    search_keyword: Optional[str] = None
    radius_km: float = 15.0
    top_n: int = 20


class ScoredPlace(BaseModel):
    place_id: str
    name: str
    category: str
    tags: list[str]
    latitude: float
    longitude: float
    avg_rating: float
    review_count: int
    description: Optional[str] = None
    taxonomy_category: str
    taxonomy_group: str
    distance_km: Optional[float] = None
    final_score: float
    content_score: float
    keyword_score: float
    taxonomy_score: float
    popularity_score: float
    distance_score: float
