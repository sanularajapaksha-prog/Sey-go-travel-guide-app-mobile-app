# SeyGo Flutter App

Cross-platform client for the SeyGo travel experience.

## Prerequisites
- Flutter 3.19+ with Android/iOS SDKs installed
- Dart 3.3+
- Backend running at `API_BASE_URL` (see below)

## Setup
1) From this folder run `flutter pub get`.
2) Create `.env` (copy `.env.example` if present) and set:
   - `API_BASE_URL=https://your-backend.example.com` (or `http://10.0.2.2:8000` for Android emulator, `http://127.0.0.1:8000` for iOS/web/desktop)
3) Launch: `flutter run` (emulator) or `flutter run -d chrome` for web.

## Notable flows
- **Auth**: register/login + OTP verification; `ApiService` handles all auth calls.
- **Places**: search, recommendations, and media display backed by Supabase.
- **Route planner**: tries backend `/route/optimize` and falls back to client-side ordering if unavailable.
- **Playlists & favourites**: create, browse, and save destinations (Map-Page + playlist merges).

## Troubleshooting
- Local backend on Android: ensure `API_BASE_URL` uses `10.0.2.2`.
- If Gradle fails after plugin changes, run `flutter clean && flutter pub get`.
- For iOS, open `ios/Runner.xcworkspace` and trust signing settings.
