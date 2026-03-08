import json
import os
import time
import urllib.parse
import urllib.request
from typing import Any

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field

router = APIRouter(prefix='/routing', tags=['routing'])


class RoutePoint(BaseModel):
    latitude: float
    longitude: float


class RouteStop(RoutePoint):
    id: Any | None = None
    name: str | None = None
    category: str | None = None
    description: str | None = None
    rating: float | None = None
    reviews: int | None = None
    image: str | None = None
    semanticLabel: str | None = None
    google_url: str | None = None


class OptimizeRouteRequest(BaseModel):
    origin: RoutePoint
    destinations: list[RouteStop] = Field(default_factory=list)


def _decode_polyline(encoded: str) -> list[dict[str, float]]:
    points: list[dict[str, float]] = []
    index = 0
    lat = 0
    lng = 0

    while index < len(encoded):
        shift = 0
        result = 0
        while True:
            b = ord(encoded[index]) - 63
            index += 1
            result |= (b & 0x1F) << shift
            shift += 5
            if b < 0x20:
                break
        dlat = ~(result >> 1) if (result & 1) else (result >> 1)
        lat += dlat

        shift = 0
        result = 0
        while True:
            b = ord(encoded[index]) - 63
            index += 1
            result |= (b & 0x1F) << shift
            shift += 5
            if b < 0x20:
                break
        dlng = ~(result >> 1) if (result & 1) else (result >> 1)
        lng += dlng

        points.append({'latitude': lat / 1e5, 'longitude': lng / 1e5})

    return points


def _format_point(lat: float, lng: float) -> str:
    return f'{lat:.7f},{lng:.7f}'


def _fetch_json(url: str) -> dict[str, Any]:
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req, timeout=20) as response:
        return json.loads(response.read().decode('utf-8'))


def _distance_matrix_seconds(
    api_key: str,
    origin: RoutePoint,
    destinations: list[RouteStop],
) -> list[int]:
    if not destinations:
        return []

    params = urllib.parse.urlencode(
        {
            'origins': _format_point(origin.latitude, origin.longitude),
            'destinations': '|'.join(
                _format_point(d.latitude, d.longitude) for d in destinations
            ),
            'mode': 'driving',
            'departure_time': int(time.time()),
            'traffic_model': 'best_guess',
            'key': api_key,
        }
    )
    url = (
        'https://maps.googleapis.com/maps/api/distancematrix/json'
        f'?{params}'
    )
    payload = _fetch_json(url)
    if payload.get('status') != 'OK':
        raise RuntimeError(payload.get('error_message', payload.get('status')))

    rows = payload.get('rows') or []
    if not rows:
        return []
    elements = rows[0].get('elements') or []
    result: list[int] = []
    for el in elements:
        if el.get('status') != 'OK':
            result.append(10**9)
            continue
        sec = (
            (el.get('duration_in_traffic') or {}).get('value')
            or (el.get('duration') or {}).get('value')
            or 10**9
        )
        result.append(int(sec))
    return result


def _directions_segment(
    api_key: str,
    origin: RoutePoint,
    destination: RoutePoint,
) -> tuple[list[dict[str, float]], float, int]:
    params = urllib.parse.urlencode(
        {
            'origin': _format_point(origin.latitude, origin.longitude),
            'destination': _format_point(
                destination.latitude, destination.longitude
            ),
            'mode': 'driving',
            'departure_time': int(time.time()),
            'traffic_model': 'best_guess',
            'key': api_key,
        }
    )
    url = 'https://maps.googleapis.com/maps/api/directions/json?' + params
    payload = _fetch_json(url)
    if payload.get('status') != 'OK':
        raise RuntimeError(payload.get('error_message', payload.get('status')))

    routes = payload.get('routes') or []
    if not routes:
        return ([], 0.0, 0)
    route = routes[0]
    leg = (route.get('legs') or [{}])[0]
    distance_km = ((leg.get('distance') or {}).get('value') or 0) / 1000.0
    duration_sec = (
        (leg.get('duration_in_traffic') or {}).get('value')
        or (leg.get('duration') or {}).get('value')
        or 0
    )
    polyline = _decode_polyline(
        (route.get('overview_polyline') or {}).get('points') or ''
    )
    return (polyline, float(distance_km), int(duration_sec))


@router.post('/optimize')
async def optimize_route(request: OptimizeRouteRequest):
    api_key = os.getenv('GOOGLE_MAPS_API_KEY', '').strip()
    if not api_key:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail='GOOGLE_MAPS_API_KEY is not configured.',
        )

    try:
        pending = [RouteStop(**d.model_dump()) for d in request.destinations]
        ordered: list[RouteStop] = []
        current = RoutePoint(
            latitude=request.origin.latitude,
            longitude=request.origin.longitude,
        )

        # Greedy optimization using traffic-aware driving durations.
        while pending:
            seconds = _distance_matrix_seconds(api_key, current, pending)
            next_index = min(range(len(pending)), key=lambda i: seconds[i])
            nxt = pending.pop(next_index)
            ordered.append(nxt)
            current = RoutePoint(latitude=nxt.latitude, longitude=nxt.longitude)

        total_distance_km = 0.0
        total_duration_sec = 0
        all_points: list[dict[str, float]] = []
        seg_origin = request.origin

        for stop in ordered:
            polyline, distance_km, duration_sec = _directions_segment(
                api_key,
                seg_origin,
                stop,
            )
            if polyline:
                if all_points and polyline:
                    all_points.extend(polyline[1:])
                else:
                    all_points.extend(polyline)
            total_distance_km += distance_km
            total_duration_sec += duration_sec
            seg_origin = RoutePoint(latitude=stop.latitude, longitude=stop.longitude)

        return {
            'optimized_stops': [s.model_dump() for s in ordered],
            'polyline_points': all_points,
            'total_distance_km': round(total_distance_km, 2),
            'total_duration_min': round(total_duration_sec / 60, 1),
        }
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f'Routing optimization failed: {exc}',
        ) from exc

