from pydantic import BaseModel, Field


class GooglePlacesSearchRequest(BaseModel):
    query: str = Field(min_length=2)
    latitude: float | None = None
    longitude: float | None = None
    radius_m: int = 50000
    max_results: int = 10
