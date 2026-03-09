from fastapi import APIRouter, Depends, status
from app.dependencies import get_authenticated_user
from app.schemas.saved_destination import SaveDestinationRequest
from app.schemas.update_destination import UpdateDestinationRequest
from app.services import destinations as destination_service

router = APIRouter(prefix="/destinations", tags=["Destinations"])

@router.post("/save", status_code=status.HTTP_201_CREATED)
def save_place(place: SaveDestinationRequest, user: dict = Depends(get_authenticated_user)):
    result = destination_service.save_destination(user["id"], place.dict())
    return {"saved": True, "data": result}

@router.get("/me")
def get_my_destinations(user: dict = Depends(get_authenticated_user)):
    destinations = destination_service.get_my_destinations(user["id"])
    return {"destinations": destinations}

@router.get("/me/paginated")
def get_my_destinations_paginated(
    page: int = 1,
    limit: int = 10,
    user: dict = Depends(get_authenticated_user),
):
    destinations = destination_service.get_my_destinations_paginated(user["id"], page, limit)
    return {"page": page, "limit": limit, "destinations": destinations}

@router.put("/{destination_id}", status_code=status.HTTP_200_OK)
def update_destination(
    destination_id: int,
    update: UpdateDestinationRequest,
    user: dict = Depends(get_authenticated_user),
):
    result = destination_service.update_destination(user["id"], destination_id, update.dict())
    return {"message": "Destination updated successfully", "data": result}

@router.delete("/{destination_id}", status_code=status.HTTP_200_OK)
def delete_destination(destination_id: int, user: dict = Depends(get_authenticated_user)):
    destination_service.delete_destination(user["id"], destination_id)
    return {"message": "Destination deleted successfully"}