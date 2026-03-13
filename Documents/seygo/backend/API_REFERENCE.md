# SeyGo Backend API Reference (summary)

Base URL: `http://localhost:8000` (dev) or configured deployment URL.

## Auth
- `POST /auth/register`  
  Body: `full_name`, `email`, `password`  
  Response: user payload + verification instructions.
- `POST /auth/login`  
  Body: `email`, `password`  
  Response: tokens and user info.
- `POST /auth/resend-verification`  
  Body: `email`
- `POST /auth/verify-otp`  
  Body: `email`, `code`

## Places
- `GET /places`  
  Query: `limit`, `offset`  
  Returns normalized place list.
- `POST /places`  
  Body: `PlaceCreate` (see schemas).
- `GET /places/search`  
  Query: `q`, optional `latitude`, `longitude`, `radius_km`, `limit`.
- `POST /places/recommend`  
  Body: `PlaceRecommendationRequest` to get personalized suggestions.

## Google proxy
- `POST /places/google/search`  
  Body: `GooglePlacesSearchRequest` (text + location).
- `GET /places/google/details/{place_id}`  
  Fetch detailed info.
- `GET /places/photo-from-google-url`  
  Query: `url` → returns proxied image URL.

## Media
- `GET /places/photo/{place_id}`  
  Returns photo stored in Supabase storage or signed URL when private.

## Destinations (user saved)
- `POST /destinations/save`  
  Save a destination record for current user.
- `POST /destinations/save-from-google`  
  Store a place fetched from Google data.
- `GET /destinations/me`  
  List current user’s saved destinations.
- `GET /destinations/me/paginated`  
  Query: `limit`, `offset`.
- `PUT /destinations/{destination_id}`  
  Update saved destination.
- `DELETE /destinations/{destination_id}`  
  Remove saved destination.

## Auth & env notes
- Requires `Authorization: Bearer <token>` for protected routes (see `app/dependencies.py`).
- Environment configured via `.env` (copy `.env.example`): `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, optional overrides for table/bucket names.

