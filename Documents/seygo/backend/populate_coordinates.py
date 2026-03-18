"""
One-time script: Fetch all places from Supabase that have no lat/lng
and populate them using Google Geocoding API.

Run from the backend folder:
    python populate_coordinates.py
"""

import os
import time
import httpx
from dotenv import load_dotenv
from supabase import create_client

load_dotenv()

SUPABASE_URL = os.environ['SUPABASE_URL']
SUPABASE_SERVICE_ROLE_KEY = os.environ['SUPABASE_SERVICE_ROLE_KEY']
GOOGLE_MAPS_API_KEY = os.environ['GOOGLE_MAPS_API_KEY']
PLACES_TABLE = os.getenv('SUPABASE_PLACES_TABLE', 'placses')

GEOCODE_URL = 'https://maps.googleapis.com/maps/api/geocode/json'


def geocode(name: str, location_hint: str = 'Sri Lanka') -> tuple[float, float] | None:
    query = f'{name}, {location_hint}'
    try:
        response = httpx.get(
            GEOCODE_URL,
            params={'address': query, 'key': GOOGLE_MAPS_API_KEY},
            timeout=10,
        )
        data = response.json()
        if data.get('status') == 'OK' and data.get('results'):
            loc = data['results'][0]['geometry']['location']
            return float(loc['lat']), float(loc['lng'])
    except Exception as e:
        print(f'  Geocoding error for "{name}": {e}')
    return None


def main():
    supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    # Fetch all places
    result = supabase.table(PLACES_TABLE).select('id, name, latitude, longitude, location').execute()
    rows = result.data or []
    print(f'Total places: {len(rows)}')

    missing = [
        r for r in rows
        if not r.get('latitude') or not r.get('longitude')
    ]
    print(f'Places missing coordinates: {len(missing)}')

    if not missing:
        print('All places already have coordinates!')
        return

    updated = 0
    failed = 0

    for place in missing:
        place_id = place['id']
        name = place.get('name') or ''
        location_hint = place.get('location') or 'Sri Lanka'

        if not name:
            print(f'  Skipping place {place_id} — no name')
            failed += 1
            continue

        print(f'  Geocoding: "{name}" ({location_hint}) ...', end=' ')
        coords = geocode(name, location_hint)

        if coords:
            lat, lng = coords
            print(f'→ {lat:.4f}, {lng:.4f}')
            supabase.table(PLACES_TABLE).update({
                'latitude': lat,
                'longitude': lng,
            }).eq('id', place_id).execute()
            updated += 1
        else:
            print(f'→ FAILED')
            failed += 1

        # Be kind to the API rate limits
        time.sleep(0.2)

    print(f'\nDone. Updated: {updated}, Failed: {failed}')


if __name__ == '__main__':
    main()
