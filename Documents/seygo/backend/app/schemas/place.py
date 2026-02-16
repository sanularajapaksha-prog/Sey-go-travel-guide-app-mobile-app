from pydantic import BaseModel


class PlaceCreate(BaseModel):
    name: str
    latitude: float
    longitude: float
    description: str | None = None
    category: str | None = None


class PlaceResponse(PlaceCreate):
    id: str | None = None
    created_by: str | None = None
