"""
route_optimizer.py
==================
Road-aware route optimizer for SeyGo trip planning.

Pipeline
--------
1. Fetch live weather for every location via Open-Meteo (free, no API key).
2. Build a pairwise travel-time/distance matrix via Google Distance Matrix API.
3. Compute a composite score for each candidate next-stop:
      score = road_time_minutes
            + weather_penalty   (0-30 extra minutes based on rain/storm severity)
            - rating_bonus      (up to 10 minutes off for highly-rated places)
4. Apply nearest-neighbour greedy TSP on the score matrix, starting from origin.
5. Fetch the actual road polyline from Google Directions API using the computed
   order (with intermediate waypoints).
6. Decode the encoded polyline and return full response.

APIs used
---------
* Google Distance Matrix API  → pairwise road travel times
* Google Directions API       → actual road polyline + confirmed distance/duration
* Open-Meteo API (free)       → current weather at each waypoint
"""

from __future__ import annotations

import logging
import math
import os
from typing import Any, Optional

import httpx

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

_GOOGLE_DISTANCE_MATRIX_URL = (
    'https://maps.googleapis.com/maps/api/distancematrix/json'
)
_GOOGLE_DIRECTIONS_URL = (
    'https://maps.googleapis.com/maps/api/directions/json'
)
_OPEN_METEO_URL = 'https://api.open-meteo.com/v1/forecast'

# WMO weather interpretation codes → human label + safety penalty (minutes)
# https://open-meteo.com/en/docs#weathervariables
_WEATHER_CODES: dict[int, tuple[str, int]] = {
    0:  ('Clear sky', 0),
    1:  ('Mainly clear', 0),
    2:  ('Partly cloudy', 0),
    3:  ('Overcast', 5),
    45: ('Fog', 10),
    48: ('Icy fog', 15),
    51: ('Light drizzle', 5),
    53: ('Moderate drizzle', 8),
    55: ('Dense drizzle', 12),
    61: ('Slight rain', 8),
    63: ('Moderate rain', 15),
    65: ('Heavy rain', 25),
    71: ('Slight snow', 10),
    73: ('Moderate snow', 20),
    75: ('Heavy snow', 30),
    77: ('Snow grains', 15),
    80: ('Slight showers', 8),
    81: ('Moderate showers', 15),
    82: ('Violent showers', 30),
    85: ('Slight snow showers', 12),
    86: ('Heavy snow showers', 25),
    95: ('Thunderstorm', 30),
    96: ('Thunderstorm + hail', 30),
    99: ('Thunderstorm + heavy hail', 30),
}

_REQUEST_TIMEOUT = 12.0  # seconds per HTTP call


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    r = 6371.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp = math.radians(lat2 - lat1)
    dl = math.radians(lon2 - lon1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def _latlng(lat: float, lon: float) -> str:
    return f'{lat},{lon}'


def decode_polyline(encoded: str) -> list[dict[str, float]]:
    """Decode a Google Maps encoded polyline string into a list of
    {latitude, longitude} dicts.
    """
    points: list[dict[str, float]] = []
    index = 0
    lat = 0
    lng = 0
    while index < len(encoded):
        # latitude
        result, shift = 0, 0
        while True:
            b = ord(encoded[index]) - 63
            index += 1
            result |= (b & 0x1F) << shift
            shift += 5
            if b < 0x20:
                break
        lat += (~result >> 1) if result & 1 else (result >> 1)
        # longitude
        result, shift = 0, 0
        while True:
            b = ord(encoded[index]) - 63
            index += 1
            result |= (b & 0x1F) << shift
            shift += 5
            if b < 0x20:
                break
        lng += (~result >> 1) if result & 1 else (result >> 1)
        points.append({'latitude': lat / 1e5, 'longitude': lng / 1e5})
    return points


# ---------------------------------------------------------------------------
# Weather (Open-Meteo — free, no API key)
# ---------------------------------------------------------------------------

def _fetch_weather(lat: float, lon: float, client: httpx.Client) -> dict[str, Any]:
    """Return weather info for a coordinate.  Never raises — returns safe defaults."""
    try:
        resp = client.get(
            _OPEN_METEO_URL,
            params={
                'latitude': lat,
                'longitude': lon,
                'current_weather': 'true',
                'wind_speed_unit': 'kmh',
            },
            timeout=_REQUEST_TIMEOUT,
        )
        resp.raise_for_status()
        data = resp.json()
        cw = data.get('current_weather', {})
        code = int(cw.get('weathercode', 0))
        label, penalty = _WEATHER_CODES.get(code, ('Unknown', 0))
        temp = cw.get('temperature', 0)
        wind = cw.get('windspeed', 0)
        # Extra wind penalty: >50 km/h add 10 min, >80 km/h add 20 min
        if wind > 80:
            penalty += 20
        elif wind > 50:
            penalty += 10
        return {
            'temperature_c': temp,
            'wind_kmh': wind,
            'condition': label,
            'weather_code': code,
            'penalty_minutes': penalty,
            'is_safe': penalty < 25,
        }
    except Exception as exc:
        logger.debug('Weather fetch failed for %.4f,%.4f: %s', lat, lon, exc)
        return {
            'temperature_c': None,
            'wind_kmh': None,
            'condition': 'Unknown',
            'weather_code': -1,
            'penalty_minutes': 0,
            'is_safe': True,
        }


# ---------------------------------------------------------------------------
# Google Distance Matrix
# ---------------------------------------------------------------------------

def _fetch_distance_matrix(
    origins: list[str],
    destinations: list[str],
    api_key: str,
    client: httpx.Client,
) -> list[list[dict[str, Any]]]:
    """Return a matrix[i][j] = {duration_sec, distance_m} or fallback haversine."""
    try:
        resp = client.get(
            _GOOGLE_DISTANCE_MATRIX_URL,
            params={
                'origins': '|'.join(origins),
                'destinations': '|'.join(destinations),
                'mode': 'driving',
                'departure_time': 'now',   # enables live traffic
                'key': api_key,
            },
            timeout=_REQUEST_TIMEOUT,
        )
        resp.raise_for_status()
        data = resp.json()
        if data.get('status') != 'OK':
            raise ValueError(f"Distance Matrix status: {data.get('status')}")

        matrix: list[list[dict]] = []
        for row in data.get('rows', []):
            cells = []
            for elem in row.get('elements', []):
                if elem.get('status') == 'OK':
                    dur = elem.get('duration_in_traffic') or elem.get('duration', {})
                    cells.append({
                        'duration_sec': dur.get('value', 9999999),
                        'distance_m': elem.get('distance', {}).get('value', 0),
                    })
                else:
                    cells.append({'duration_sec': 9999999, 'distance_m': 0})
            matrix.append(cells)
        return matrix
    except Exception as exc:
        logger.warning('Distance Matrix API failed: %s — using haversine fallback', exc)
        return []   # caller will use haversine


# ---------------------------------------------------------------------------
# Nearest-neighbour TSP on composite score matrix
# ---------------------------------------------------------------------------

def _nearest_neighbour_tsp(
    locations: list[dict[str, Any]],   # [origin, dest0, dest1, ...]
    matrix: list[list[dict]],          # pairwise travel data (may be empty)
    weather: list[dict],               # per-location weather (index matches locations)
) -> list[int]:
    """Return indices into locations[1:] (destination indices) in visit order.

    Scoring per candidate next stop:
      score = road_duration_minutes
            + weather_penalty
            - min(rating * 2, 10)   (max 10-minute bonus for a 5-star place)
    Lower is better.
    """
    n_dest = len(locations) - 1  # number of destinations (exclude origin)
    unvisited = list(range(n_dest))   # indices into destinations list
    order: list[int] = []
    current_idx = 0  # start at origin (index 0 in locations)

    while unvisited:
        best_i = -1
        best_score = float('inf')
        for dest_i in unvisited:
            loc_idx = dest_i + 1  # offset because locations[0] = origin
            # Travel time
            if matrix:
                dur_sec = matrix[current_idx][loc_idx]['duration_sec']
                dur_min = dur_sec / 60.0
            else:
                # Haversine fallback (assume ~60 km/h avg speed)
                km = _haversine_km(
                    locations[current_idx]['latitude'],
                    locations[current_idx]['longitude'],
                    locations[loc_idx]['latitude'],
                    locations[loc_idx]['longitude'],
                )
                dur_min = (km / 60.0) * 60  # km ÷ speed × 60

            # Weather penalty at destination
            w_penalty = weather[loc_idx]['penalty_minutes'] if weather else 0

            # Rating bonus (higher rating → deduct from score)
            rating = float(locations[loc_idx].get('rating') or 0.0)
            rating_bonus = min(rating * 2.0, 10.0)

            score = dur_min + w_penalty - rating_bonus

            if score < best_score:
                best_score = score
                best_i = dest_i

        order.append(best_i)
        current_idx = best_i + 1
        unvisited.remove(best_i)

    return order


# ---------------------------------------------------------------------------
# Google Directions API → road polyline + confirmed distance/duration
# ---------------------------------------------------------------------------

def _fetch_directions(
    origin_ll: str,
    destination_ll: str,
    waypoints: list[str],
    api_key: str,
    client: httpx.Client,
) -> dict[str, Any]:
    """Call Directions API with ordered waypoints.  Returns raw API response."""
    params: dict[str, Any] = {
        'origin': origin_ll,
        'destination': destination_ll,
        'mode': 'driving',
        'departure_time': 'now',
        'key': api_key,
    }
    if waypoints:
        params['waypoints'] = '|'.join(waypoints)

    resp = client.get(_GOOGLE_DIRECTIONS_URL, params=params, timeout=_REQUEST_TIMEOUT)
    resp.raise_for_status()
    return resp.json()


def _parse_directions(directions_data: dict) -> tuple[list[dict], float, float]:
    """Extract polyline points, total distance (km) and duration (min)."""
    routes = directions_data.get('routes', [])
    if not routes:
        return [], 0.0, 0.0

    route = routes[0]
    overview_polyline = route.get('overview_polyline', {}).get('points', '')
    polyline_points = decode_polyline(overview_polyline) if overview_polyline else []

    total_dist_m = 0.0
    total_dur_sec = 0.0
    for leg in route.get('legs', []):
        total_dist_m += leg.get('distance', {}).get('value', 0)
        dur = leg.get('duration_in_traffic') or leg.get('duration', {})
        total_dur_sec += dur.get('value', 0)

    return polyline_points, total_dist_m / 1000.0, total_dur_sec / 60.0


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def optimize_route(
    origin: dict[str, Any],
    destinations: list[dict[str, Any]],
) -> dict[str, Any]:
    """Full route optimization pipeline.

    Parameters
    ----------
    origin : {'latitude': float, 'longitude': float, ...}
    destinations : list of place dicts (must have latitude, longitude)

    Returns
    -------
    {
      'optimized_stops':  list of destination dicts in visit order,
      'polyline_points':  [{'latitude': float, 'longitude': float}, ...],
      'total_distance_km': float,
      'total_duration_min': float,
      'weather_info':     list of per-stop weather dicts,
      'optimization_method': 'google_directions' | 'haversine_fallback',
    }
    """
    api_key = os.getenv('GOOGLE_MAPS_API_KEY', '').strip()

    if not destinations:
        return {
            'optimized_stops': [],
            'polyline_points': [],
            'total_distance_km': 0.0,
            'total_duration_min': 0.0,
            'weather_info': [],
            'optimization_method': 'no_destinations',
        }

    with httpx.Client(follow_redirects=True, timeout=20.0) as client:
        # ---- Step 1: Fetch weather for all locations ----
        all_locations = [origin] + list(destinations)
        weather_data: list[dict] = []
        for loc in all_locations:
            w = _fetch_weather(
                float(loc['latitude']),
                float(loc['longitude']),
                client,
            )
            weather_data.append(w)

        # ---- Step 2: Distance matrix (if API key available) ----
        distance_matrix: list[list[dict]] = []
        if api_key:
            coord_strings = [
                _latlng(float(loc['latitude']), float(loc['longitude']))
                for loc in all_locations
            ]
            distance_matrix = _fetch_distance_matrix(
                coord_strings, coord_strings, api_key, client
            )

        # ---- Step 3: TSP nearest-neighbour on composite scores ----
        if len(destinations) == 1:
            ordered_dest_indices = [0]
        else:
            ordered_dest_indices = _nearest_neighbour_tsp(
                all_locations, distance_matrix, weather_data
            )

        ordered_destinations = [destinations[i] for i in ordered_dest_indices]
        ordered_weather = [weather_data[i + 1] for i in ordered_dest_indices]

        # ---- Step 4: Fetch actual road polyline from Directions API ----
        polyline_points: list[dict] = []
        total_distance_km = 0.0
        total_duration_min = 0.0
        method = 'haversine_fallback'

        if api_key:
            try:
                origin_ll = _latlng(
                    float(origin['latitude']), float(origin['longitude'])
                )
                dest_ll = _latlng(
                    float(ordered_destinations[-1]['latitude']),
                    float(ordered_destinations[-1]['longitude']),
                )
                waypoint_lls = [
                    _latlng(float(d['latitude']), float(d['longitude']))
                    for d in ordered_destinations[:-1]
                ]

                directions = _fetch_directions(
                    origin_ll, dest_ll, waypoint_lls, api_key, client
                )
                if directions.get('status') == 'OK':
                    polyline_points, total_distance_km, total_duration_min = (
                        _parse_directions(directions)
                    )
                    method = 'google_directions'
                else:
                    logger.warning(
                        'Directions API returned status: %s',
                        directions.get('status'),
                    )
            except Exception as exc:
                logger.warning('Directions API call failed: %s', exc)

        # Haversine fallback for distance/polyline when Directions API fails
        if not polyline_points:
            polyline_points = [
                {'latitude': float(origin['latitude']), 'longitude': float(origin['longitude'])}
            ]
            for d in ordered_destinations:
                polyline_points.append({
                    'latitude': float(d['latitude']),
                    'longitude': float(d['longitude']),
                })
            # Estimate distance + time (~50 km/h average road speed in Sri Lanka)
            total_distance_km = sum(
                _haversine_km(
                    float(polyline_points[i]['latitude']),
                    float(polyline_points[i]['longitude']),
                    float(polyline_points[i + 1]['latitude']),
                    float(polyline_points[i + 1]['longitude']),
                )
                for i in range(len(polyline_points) - 1)
            )
            total_duration_min = (total_distance_km / 50.0) * 60.0

        return {
            'optimized_stops': ordered_destinations,
            'polyline_points': polyline_points,
            'total_distance_km': round(total_distance_km, 2),
            'total_duration_min': round(total_duration_min, 1),
            'weather_info': [
                {
                    'stop_name': ordered_destinations[i].get('name', ''),
                    **ordered_weather[i],
                }
                for i in range(len(ordered_destinations))
            ],
            'optimization_method': method,
        }
