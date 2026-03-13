# Troubleshooting (Flutter client)

## Build / toolchain
- **`Operation not permitted` writing Flutter cache**: run with proper permissions or clear `~/flutter/bin/cache` (may require sudo outside sandbox).
- **Gradle license errors**: accept licenses `yes | sdkmanager --licenses`.
- **Xcode signing failed**: open `ios/Runner.xcworkspace`, set Team + Bundle ID, and ensure provisioning profile is automatic.

## Runtime / networking
- **Android emulator can’t reach backend**: set `API_BASE_URL=http://10.0.2.2:8000` in `.env`. Web/iOS/macOS use `http://127.0.0.1:8000`.
- **401 after login**: verify backend Supabase keys and that tokens are being returned; check `supabase.auth.get_user` in backend.
- **Images not showing**: ensure Supabase storage bucket is public or signed URLs are enabled (`SUPABASE_PLACE_PHOTOS_PRIVATE` + service role key).

## Flutter common fixes
- `flutter clean && flutter pub get`
- Delete `ios/Pods` and `Podfile.lock`, then `pod install --repo-update`.
- For web caching issues: open DevTools → Application → Clear storage.

## Map/route planner
- If backend routing unavailable, client fallback runs automatically (no crash). You’ll see “Road routing unavailable” snackbar; ensure `/route/optimize` is implemented backend-side for full experience.
- If Google Maps SDK complains about API key: set the key in `android/app/src/main/AndroidManifest.xml` and iOS `AppDelegate.swift`/`Info.plist` as required.

## Auth/OTP
- Emails not arriving: check Supabase SMTP settings; use `supabase.auth.admin.generateLink` to test.
- OTP fail: confirm `code` is trimmed and backend `verify-otp` endpoint reachable.

## Performance tips
- Prefer release/profile builds on device when checking map animations.
- Limit rebuilds: keep heavy widgets out of `setState` loops; use providers for shared state.

