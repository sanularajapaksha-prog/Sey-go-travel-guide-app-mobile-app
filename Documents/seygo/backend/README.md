# SeyGo Backend (FastAPI + Supabase)

## Run locally
1) `cd Documents/seygo/backend`
2) Create env: `cp .env.example .env` and set:
   - `SUPABASE_URL`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `SUPABASE_ANON_KEY` (if needed for public reads)
   - Optional: `SUPABASE_PLACES_TABLE`, `SUPABASE_PLACE_PHOTOS_BUCKET`, `SUPABASE_PLACE_PHOTOS_PRIVATE`
3) Install deps: `pip install -r requirements.txt`
4) Start API: `uvicorn app.main:app --reload --host 0.0.0.0 --port 8000`

## Key endpoints
- `POST /auth/register` – create user
- `POST /auth/login` – JWT login
- `POST /auth/resend-verification` / `POST /auth/verify-otp`
- `GET /places` – paginated places list
- `GET /places/search` – text + geo search
- `POST /places/recommend` – recommendations
- `POST /google/search` / `GET /google/details/{place_id}` – Google Places proxy
- `GET /photo/{place_id}` – stored photo retrieval

## Notes
- `app/dependencies.py` loads `.env` at runtime; missing keys raise at startup.
- Storage URLs use public or signed URLs depending on `SUPABASE_PLACE_PHOTOS_PRIVATE`.
- For local dev with Android emulator, ensure the front-end uses `10.0.2.2` to reach `localhost:8000`.
