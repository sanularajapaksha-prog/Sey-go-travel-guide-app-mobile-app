"""
Re-seed the placses table in Supabase from the cached semantic_places.json file.
Run from the backend directory:
    python seed_places.py
"""
import json
import os
import sys
from pathlib import Path

from dotenv import load_dotenv
from supabase import create_client

load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL', '')
SUPABASE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY', '')
PLACES_TABLE = os.getenv('SUPABASE_PLACES_TABLE', 'placses')
JSON_PATH    = Path(__file__).parent / 'ml_models' / 'semantic_places.json'
BATCH_SIZE   = 100


def _clean_row(row: dict) -> dict:
    """Return only the columns that exist in the DB (strip ML-only/computed fields)."""
    lat = row.get('lat') or row.get('_lat')
    lng = row.get('lng') or row.get('_lng')
    return {
        'place_id':           row.get('place_id'),
        'name':               row.get('name'),
        'primary_category':   row.get('primary_category'),
        'categories':         json.dumps(row['categories']) if isinstance(row.get('categories'), list) else row.get('categories'),
        'category_confidence':row.get('category_confidence'),
        'lat':                lat,
        'lng':                lng,
        'latitude':           lat,
        'longitude':          lng,
        'address':            row.get('address'),
        'website':            row.get('website'),
        'google_url':         row.get('google_url'),
        'avg_rating':         row.get('avg_rating'),
        'review_count':       row.get('review_count'),
        'types':              json.dumps(row['types']) if isinstance(row.get('types'), list) else row.get('types'),
        'photo_storage_paths':json.dumps(row['photo_storage_paths']) if isinstance(row.get('photo_storage_paths'), list) else row.get('photo_storage_paths'),
        'seed_area':          row.get('seed_area'),
        'status':             row.get('status', 'active'),
    }


def main():
    if not SUPABASE_URL or not SUPABASE_KEY:
        print('ERROR: SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY not set in .env')
        sys.exit(1)

    print(f'Loading places from {JSON_PATH} ...')
    with open(JSON_PATH, encoding='utf-8') as f:
        raw = json.load(f)
    print(f'  {len(raw)} places found in JSON cache.')

    rows = [_clean_row(r) for r in raw if r.get('place_id')]
    print(f'  {len(rows)} rows prepared for upsert.')

    supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

    inserted = 0
    for i in range(0, len(rows), BATCH_SIZE):
        batch = rows[i:i + BATCH_SIZE]
        try:
            supabase.table(PLACES_TABLE).upsert(batch, on_conflict='place_id').execute()
            inserted += len(batch)
            print(f'  Upserted {inserted}/{len(rows)} ...', end='\r')
        except Exception as exc:
            print(f'\nERROR at batch {i}: {exc}')
            # Try row-by-row for this batch to skip bad rows
            for row in batch:
                try:
                    supabase.table(PLACES_TABLE).upsert(row, on_conflict='place_id').execute()
                    inserted += 1
                except Exception as row_exc:
                    print(f'  Skipped {row.get("place_id")}: {row_exc}')

    print(f'\nDone. {inserted} rows upserted into "{PLACES_TABLE}".')


if __name__ == '__main__':
    main()
