from typing import Optional

from pydantic import BaseModel, Field


class UserContext(BaseModel):
    user_id: str
    preference_tags: list[str] = Field(default_factory=list)
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    search_keyword: Optional[str] = None
    radius_km: float = 15.0


class Place(BaseModel):
    place_id: str
    name: str
    category: str
    tags: list[str]
    latitude: float
    longitude: float
    avg_rating: float = 0.0
    review_count: int = 0
    description: Optional[str] = None


class RecommendationRequest(BaseModel):
    user: UserContext
    places: list[Place]
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
    distance_km: Optional[float] = None
    final_score: float
    content_score: float
    keyword_score: float
    popularity_score: float
    distance_score: float


class RecommendationResponse(BaseModel):
    recommendations: list[ScoredPlace]
