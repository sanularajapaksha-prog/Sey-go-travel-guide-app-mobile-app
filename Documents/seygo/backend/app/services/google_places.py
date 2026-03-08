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
