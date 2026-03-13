# Deployment Playbook (SeyGo)

## Front-end (Flutter)
### Android
1) From `Documents/seygo/front-end`: `flutter clean && flutter pub get`.
2) Set app id/signing in `android/app/build.gradle.kts`.
3) Build: `flutter build apk --release` or `flutter build appbundle`.
4) Upload AAB to Play Console.

### iOS
1) `flutter pub get`; open `Documents/seygo/front-end/ios/Runner.xcworkspace` in Xcode.
2) Set team & bundle id; ensure `Info.plist` permissions are correct.
3) Build archive via Xcode; distribute through App Store Connect.

### Web
1) `flutter build web --release`.
2) Deploy contents of `build/web` to static hosting (CloudFront, Vercel, Netlify).

### Desktop (macOS/Windows/Linux)
1) Enable platform: `flutter config --enable-macos-desktop` (etc.).
2) Build: `flutter build macos` / `windows` / `linux`.

## Backend (FastAPI + Supabase)
1) Env: set `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, optional bucket/table overrides.
2) Dependencies: `pip install -r requirements.txt`.
3) Prod server: `uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4` behind a reverse proxy.
4) Static files/media: stored in Supabase storage; ensure bucket privacy matches `SUPABASE_PLACE_PHOTOS_PRIVATE`.
5) Health: add uptime checks on `/places` and `/auth/login` (HEAD or GET).

## CI/CD suggestions
- Lint/test: `flutter analyze`, `flutter test`, `pytest` for backend.
- Cache pub packages and pip wheels to speed builds.
- Fail build if `.env.example` is out of sync with code-required keys.

