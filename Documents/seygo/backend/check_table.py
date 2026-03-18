import os
from dotenv import load_dotenv
from supabase import create_client

load_dotenv()

supabase = create_client(os.environ['SUPABASE_URL'], os.environ['SUPABASE_SERVICE_ROLE_KEY'])
PLACES_TABLE = os.getenv('SUPABASE_PLACES_TABLE', 'placses')

result = supabase.table(PLACES_TABLE).select('*').limit(2).execute()
rows = result.data or []

if rows:
    print('Columns:', list(rows[0].keys()))
    print('\nFirst row:')
    for k, v in rows[0].items():
        print(f'  {k}: {repr(v)[:80]}')
else:
    print('No rows found in table:', PLACES_TABLE)
