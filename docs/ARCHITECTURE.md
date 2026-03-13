# Architecture Overview

## High level
- **Front-end**: Flutter app (mobile/web/desktop) living under `Documents/seygo/front-end`. Uses providers for theme/font scale, service layer for API calls, and feature screens for auth, playlists, route planner, and welcome/home flows.
- **Back-end**: FastAPI service under `Documents/seygo/backend`, backed by Supabase for auth, database, and storage.
- **API contract**: JSON over HTTPS. Base URL configured via `API_BASE_URL` env for the app. Authentication via bearer token.

## Front-end structure (key folders)
- `lib/data/services/` – API clients (`api_service.dart`).
- `lib/presentation/` – Screens (login, register, splash, welcome_home, map_view, playlists, profile, route_planner, destination_detail, etc.).
- `lib/providers/` – `theme_provider.dart`, `font_scale_provider.dart`, `favorites_provider.dart`.
- `lib/routes/` – Route names and navigation map.
- `lib/theme/` – Colors, typography, dark/light theming.
- `assets/` – Images and animations used across onboarding, destination cards, and playlists.

### Navigation
- Defined in `lib/routes/app_routes.dart`.
- Splash → Intro → Auth (login/register) → Welcome Home → Map/Playlists/Profile.
- Route planner screen reachable from home drawer/bottom bar.

### State management
- Lightweight Provider (no bloc) for theme/font/favorites.
- Local widget state for flows like route optimization and map selections.

### Network layer
- `ApiService` centralizes endpoints. Fallbacks:
  - Base URL chooses 10.0.2.2 for Android emulator, 127.0.0.1 otherwise.
  - Route planner has graceful client-side fallback when backend optimization unavailable.

## Back-end structure
- `app/main.py` – FastAPI app creation and router inclusion.
- `app/dependencies.py` – Supabase client loading, auth dependencies.
- `app/routers/` – `auth.py`, `places.py`, `destinations.py` (save/load user destinations).
- `app/schemas/` – Pydantic models for requests/responses.
- `app/services/` – Google Places integration, recommender, taxonomy helpers.
- `.env` config: Supabase URL/keys, table/bucket names, private/public storage flags.

## Data flow: Places search
1) User types a query on front-end search.
2) `ApiService.searchPlacesFromDb` hits `/places/search`.
3) Backend `places.py` queries Supabase, normalizes media URLs, returns list.
4) Front-end renders destination cards with photo URLs (public or signed).

## Data flow: Auth + OTP
1) Register/Login via `/auth/register` or `/auth/login`.
2) Tokens returned; app stores token in memory (persist as needed).
3) OTP verification via `/auth/verify-otp`; resend via `/auth/resend-verification`.

## Data flow: Route planner
1) Front-end collects origin + destinations.
2) Tries POST `/route/optimize` (planned backend endpoint); until then, client fallback keeps UX working.
3) Polyline/metrics rendered on map; on failure, nearest-neighbor ordering is used.

## Environment configuration
- **Front-end**: `.env` with `API_BASE_URL`. Defaults adjust for emulator vs desktop/web.
- **Back-end**: `.env` with Supabase keys. `.env.example` documents required keys.

## Logging & monitoring
- Flutter: minimal; logs to console. Add `frontend.log` when running dev.
- Backend: stdout/stderr logs; add structured logging in `app/main.py` for production.

## Future improvements
- Add dedicated `/route/optimize` endpoint with caching.
- Persist favorites/playlists via Supabase tables with RLS.
- Move images to CDN-backed public bucket, signed URLs only for private content.
- Add CI to run `flutter analyze`, `flutter test`, and `pytest`.

