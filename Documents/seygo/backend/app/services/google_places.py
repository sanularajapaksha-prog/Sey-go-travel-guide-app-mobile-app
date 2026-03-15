import os

import httpx

from ..schemas.google_places import GooglePlacesSearchRequest
from .place_taxonomy import infer_taxonomy


class GooglePlacesService:
    def __init__(self) -> None:
        self.api_key = os.getenv('GOOGLE_MAPS_API_KEY', '')
        self.base_url = 'https://places.googleapis.com/v1'

    def _ensure_api_key(self) -> None:
        if not self.api_key:
            raise RuntimeError('GOOGLE_MAPS_API_KEY is not configured.')

    def search_places(self, request: GooglePlacesSearchRequest) -> dict:
        self._ensure_api_key()

        query_text = request.query.strip()
        if query_text and 'sri lanka' not in query_text.lower():
            query_text = f'{query_text} Sri Lanka'

        headers = {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': self.api_key,
            'X-Goog-FieldMask': (
                'places.id,places.name,places.displayName,places.formattedAddress,'
                'places.location,places.primaryType,places.types,places.rating,'
                'places.userRatingCount'
            ),
        }

        payload: dict = {
            'textQuery': query_text,
            'maxResultCount': request.max_results,
            'rankPreference': 'RELEVANCE',
            'includedRegionCodes': ['LK'],
        }

        if request.latitude is not None and request.longitude is not None:
            payload['locationBias'] = {
                'circle': {
                    'center': {
                        'latitude': request.latitude,
                        'longitude': request.longitude,
                    },
                    'radius': float(request.radius_m),
                }
            }

        with httpx.Client(timeout=15.0) as client:
            response = client.post(
                f'{self.base_url}/places:searchText',
                headers=headers,
                json=payload,
            )
            response.raise_for_status()
            data = response.json()

        places = data.get('places', [])
        normalized = []
        for place in places:
            name = (place.get('displayName') or {}).get('text') or ''
            formatted_address = place.get('formattedAddress')
            types = place.get('types') or []
            primary_type = place.get('primaryType') or ''
            taxonomy_category, taxonomy_group = infer_taxonomy(
                name=name,
                category=primary_type,
                tags=types,
                description=formatted_address,
            )
            normalized.append(
                {
                    'id': place.get('id'),
                    'name': name,
                    'formatted_address': formatted_address,
                    'latitude': (place.get('location') or {}).get('latitude'),
                    'longitude': (place.get('location') or {}).get('longitude'),
                    'primary_type': primary_type,
                    'types': types,
                    'rating': place.get('rating'),
                    'user_rating_count': place.get('userRatingCount'),
                    'resource_name': place.get('name'),
                    'taxonomy_category': taxonomy_category,
                    'taxonomy_group': taxonomy_group,
                }
            )
        return {'count': len(normalized), 'places': normalized}

    def place_details(self, place_id: str) -> dict:
        self._ensure_api_key()

        headers = {
            'X-Goog-Api-Key': self.api_key,
            'X-Goog-FieldMask': (
                'id,name,displayName,formattedAddress,location,primaryType,types,'
                'rating,userRatingCount,websiteUri,googleMapsUri,nationalPhoneNumber,'
                'editorialSummary,regularOpeningHours'
            ),
        }
        with httpx.Client(timeout=15.0) as client:
            response = client.get(
                f'{self.base_url}/places/{place_id}',
                headers=headers,
            )
            response.raise_for_status()
            place = response.json()

        name = (place.get('displayName') or {}).get('text') or ''
        formatted_address = place.get('formattedAddress')
        types = place.get('types') or []
        primary_type = place.get('primaryType') or ''
        taxonomy_category, taxonomy_group = infer_taxonomy(
            name=name,
            category=primary_type,
            tags=types,
            description=formatted_address,
        )

        return {
            'id': place.get('id'),
            'name': name,
            'formatted_address': formatted_address,
            'latitude': (place.get('location') or {}).get('latitude'),
            'longitude': (place.get('location') or {}).get('longitude'),
            'primary_type': primary_type,
            'types': types,
            'rating': place.get('rating'),
            'user_rating_count': place.get('userRatingCount'),
            'website_uri': place.get('websiteUri'),
            'google_maps_uri': place.get('googleMapsUri'),
            'phone_number': place.get('nationalPhoneNumber'),
            'editorial_summary': (place.get('editorialSummary') or {}).get('text'),
            'opening_hours': (place.get('regularOpeningHours') or {}).get('weekdayDescriptions') or [],
            'resource_name': place.get('name'),
            'taxonomy_category': taxonomy_category,
            'taxonomy_group': taxonomy_group,
        }
        
    def get_multi_stop_route(self, stops: list[dict]) -> dict:
  
    self._ensure_api_key()

    if len(stops) < 2:
        raise ValueError('At least 2 stops are required for a route.')

    base_url = 'https://maps.googleapis.com/maps/api/directions/json'

    origin = f"{stops[0]['latitude']},{stops[0]['longitude']}"
    destination = f"{stops[-1]['latitude']},{stops[-1]['longitude']}"

    waypoints = '|'.join(
        f"{stop['latitude']},{stop['longitude']}"
        for stop in stops[1:-1]
    )

    params = {
        'origin': origin,
        'destination': destination,
        'key': self.api_key,
    }
    if waypoints:
        params['waypoints'] = waypoints

    with httpx.Client(timeout=15.0) as client:
        response = client.get(base_url, params=params)
        response.raise_for_status()
        data = response.json()

    if data.get('status') != 'OK':
        raise RuntimeError(f"Google Directions error: {data.get('status')} — {data.get('error_message', '')}")

    route = data['routes'][0]
    legs = route['legs']

    leg_summaries = []
    for i, leg in enumerate(legs):
        leg_summaries.append({
            'from': stops[i]['name'],
            'to': stops[i + 1]['name'],
            'distance_km': round(leg['distance']['value'] / 1000, 2),
            'duration_minutes': round(leg['duration']['value'] / 60, 1),
            'start_location': leg['start_location'],
            'end_location': leg['end_location'],
        })

    total_distance_km = round(sum(l['distance']['value'] for l in legs) / 1000, 2)
    total_duration_minutes = round(sum(l['duration']['value'] for l in legs) / 60, 1)

    return {
        'total_stops': len(stops),
        'total_distance_km': total_distance_km,
        'total_duration_minutes': total_duration_minutes,
        'stops': [{'name': s['name'], 'latitude': s['latitude'], 'longitude': s['longitude']} for s in stops],
        'legs': leg_summaries,
        'polyline': route['overview_polyline']['points'],  # encoded polyline for Flutter map rendering
    }
