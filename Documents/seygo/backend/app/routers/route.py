"""
route.py
========
FastAPI router for route optimization.

Endpoint
--------
POST /route/optimize
    Accepts origin + list of destination places.
    Returns the optimized visit order, actual road polyline, total distance
    and duration, and live weather at every stop.
"""

from __future__ import annotations

from typing import Any, Optional

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field

from ..services.route_optimizer import optimize_route

router = APIRouter(prefix='/route', tags=['route'])


# ---------------------------------------------------------------------------
# Request / response schemas
# ---------------------------------------------------------------------------

class _LatLng(BaseModel):
    latitude: float
    longitude: float


class RouteOptimizeRequest(BaseModel):
    origin: dict[str, Any] = Field(
        ...,
        description='Origin location with at least latitude and longitude keys.',
        examples=[{'latitude': 7.873, 'longitude': 80.771}],
    )
    destinations: list[dict[str, Any]] = Field(
        ...,
        description='Ordered list of place dicts (must include latitude, longitude).',
        min_length=1,
    )


class RouteOptimizeResponse(BaseModel):
    optimized_stops: list[dict[str, Any]]
    polyline_points: list[dict[str, float]]
    total_distance_km: float
    total_duration_min: float
    weather_info: list[dict[str, Any]]
    optimization_method: str


# ---------------------------------------------------------------------------
# Endpoint
# ---------------------------------------------------------------------------

def _validate_coords(lat: Any, lng: Any, label: str) -> None:
    try:
        lat, lng = float(lat), float(lng)
    except (TypeError, ValueError):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f'{label}: latitude and longitude must be numbers.',
        )
    if not (-90 <= lat <= 90):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f'{label}: latitude must be between -90 and 90.',
        )
    if not (-180 <= lng <= 180):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f'{label}: longitude must be between -180 and 180.',
        )


@router.post(
    '/optimize',
    response_model=RouteOptimizeResponse,
    summary='Optimize route for multiple destinations',
    description=(
        'Given an origin and a list of destinations, returns the optimal '
        'visit order using road travel times (Google Distance Matrix API + '
        'weather-aware scoring), plus the road polyline from Google Directions '
        'API.  Falls back gracefully to straight-line haversine ordering when '
        'the Google APIs are unavailable.'
    ),
)
async def optimize_route_endpoint(request: RouteOptimizeRequest):
    if 'latitude' not in request.origin or 'longitude' not in request.origin:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail='origin must contain latitude and longitude.',
        )
    _validate_coords(request.origin['latitude'], request.origin['longitude'], 'origin')

    for i, dest in enumerate(request.destinations):
        if 'latitude' not in dest or 'longitude' not in dest:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f'destinations[{i}] must contain latitude and longitude.',
            )
        _validate_coords(dest['latitude'], dest['longitude'], f'destinations[{i}]')

    try:
        result = optimize_route(
            origin=request.origin,
            destinations=request.destinations,
        )
        return result
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f'Route optimization failed: {exc}',
        ) from exc
