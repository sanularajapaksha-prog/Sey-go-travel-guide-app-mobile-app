# SeyGo Travel Guide

Unified mobile + backend repo for the SeyGo travel experience: Flutter front-end (Android/iOS/web/desktop) talking to a FastAPI backend backed by Supabase.

## Repo layout
- `Documents/seygo/front-end/` – Flutter app sources, assets, platform folders.
- `Documents/seygo/backend/` – FastAPI service, routers, schemas, services.
- `android/ ios/ linux/ macos/ windows/ web/` – Flutter scaffolding from Map-Page/playlist merges (kept for platform builds).

## Quick start (local)
1) Clone & fetch: `git clone` then `git submodule update --init --recursive` (none today, but keeps CI happy).
2) Install Flutter (>=3.19) & Dart; run `flutter doctor`.
3) Install backend deps: `pip install -r Documents/seygo/backend/requirements.txt`.
4) Copy env: `cp Documents/seygo/backend/.env.example Documents/seygo/backend/.env` and fill Supabase keys.
5) Run backend: `uvicorn app.main:app --reload --host 0.0.0.0 --port 8000` from `Documents/seygo/backend`.
6) Run app: from `Documents/seygo/front-end`, run `flutter pub get` then `flutter run` (emulator) or `flutter run -d chrome`.

## API base URL
The app reads `API_BASE_URL` from `Documents/seygo/front-end/.env`; falls back to local emulator defaults:
- Android emulator → `http://10.0.2.2:8000`
- iOS/web/desktop → `http://127.0.0.1:8000`

## Key features merged
- Authentication: register/login + OTP verification.
- Places search (Supabase) with recommendations and media handling.
- Route planner with graceful client fallback when backend routing is unavailable.
- Playlists & favourites (Map-Page + playlist merges).

## Development tips
- Keep `.env` out of git; use `.env.example` updates for new keys.
- Prefer small, focused feature branches; rebase or merge with `--no-ff` as team prefers.
- Regenerate platform files only when bumping Flutter or adding plugins.

