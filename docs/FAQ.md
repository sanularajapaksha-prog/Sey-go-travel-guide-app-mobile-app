# FAQ

**Q: Why can’t Android emulator reach the backend on localhost?**  
A: Use `http://10.0.2.2:8000` as `API_BASE_URL`. The emulator maps that to your host loopback.

**Q: Web build shows CORS errors.**  
A: Enable CORS on FastAPI (use `CORSMiddleware`) and ensure correct origins for staging/production.

**Q: Images not loading from Supabase.**  
A: Set bucket to public or use signed URLs. Check `SUPABASE_PLACE_PHOTOS_PRIVATE` and service role key.

**Q: OTP emails not arriving.**  
A: Verify Supabase SMTP settings; in staging use mailtrap/test inbox. Resend via `/auth/resend-verification`.

**Q: Route planner says “Road routing unavailable.”**  
A: Backend `/route/optimize` not implemented or unreachable; client fallback still works. Check network/base URL.

**Q: How do I change app colors?**  
A: Update `lib/theme/app_theme.dart`; keep contrast; run `flutter analyze` afterwards.

**Q: What Android permissions are required?**  
A: See `android/app/src/main/AndroidManifest.xml`—location, internet, maps key meta-data.

**Q: iOS build fails with signing issues.**  
A: Open `ios/Runner.xcworkspace` and set Team + Bundle ID. Clean derived data if needed.

**Q: What are the Supabase tables used?**  
A: `places` (or override via `SUPABASE_PLACES_TABLE`), user auth tables, optional destinations/favourites tables.

**Q: How to reset local caches?**  
A: `flutter clean && flutter pub get`; remove `ios/Pods` + reinstall; clear web cache via DevTools.

**Q: Does the app work offline?**  
A: Limited—most data fetched live. Route planner has client fallback but still needs initial data.

