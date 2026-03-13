# Test Plan (SeyGo)

## Scope
This plan covers core user flows across front-end (Flutter) and back-end (FastAPI). Focus: auth, places search, recommendations, playlists/favourites, route planner, and offline/edge cases.

## Environments
- **Local dev**: backend on `http://127.0.0.1:8000`, Android emulator uses `10.0.2.2`.
- **Staging**: supabase staging project, CDN for images.
- **Production**: TBD; same test suite with reduced destructive tests.

## Test matrix
- Devices: Android emulator (API 33), iOS simulator (iOS 17), Chrome (web), macOS desktop.
- Network: wifi, throttled 3G, offline.
- Auth state: logged-out, logged-in (verified), logged-in (unverified).

## Functional test cases
### Authentication
1. Register with valid data → success, verification required.
2. Register duplicate email → error message.
3. Login with valid credentials → lands on welcome screen.
4. Login wrong password → error shown, no crash.
5. Resend verification → email/success toast.
6. Verify OTP correct code → account marked verified.
7. Verify OTP wrong/expired code → error shown.

### Places search
1. Search text only → results list populated.
2. Search with geo params → results sorted by distance.
3. Empty results → empty state displayed.
4. Slow backend (artificial delay) → loading indicator, eventual success.
5. Backend 500 → error snackbar; no crash.

### Recommendations
1. Recommend with liked_tags → receives list ordered by relevance.
2. Recommend with disliked_tags → excluded tags not present.
3. Missing auth token → 401 handled gracefully.

### Destinations (user saved)
1. Save destination → persists and appears in “My Destinations”.
2. Update destination notes → saved changes visible after refresh.
3. Delete destination → removed from list.
4. Pagination → loads next page correctly.

### Playlists / Favourites
1. Create playlist → appears in playlist screen.
2. Add destination to playlist → count increments.
3. Remove destination → updates UI immediately.
4. Favourite toggle → persists after app restart.

### Route planner
1. Optimize with 3 stops → polyline + stats shown.
2. Backend route optimize down → client fallback ordering, snackbar message.
3. Clear cart → map resets to origin marker only.
4. Invalid coordinates → validation error shown.

### UI / Navigation
1. Splash → Intro → Auth → Home flow.
2. Theme toggle (light/dark) persists across app restart.
3. Font scale provider adjusts text sizes globally.
4. Bottom bar navigation between Home / Map / Profile / Playlists.

### Profile / Settings
1. Update appearance (theme/font) → immediate UI change.
2. Help/Support popup opens with links.
3. Notifications panel toggles switches without crash.

## Non-functional
### Performance
- Cold start under 3s on emulator (release/profile).
- Route planner optimize call < 3s with backend available.
- Image grid lazy-load does not jank on scroll.

### Accessibility
- Text scaling via font_scale_provider respected.
- Buttons tappable at 44x44 minimum.
- Color contrast meets WCAG AA for primary actions.

### Security
- Token stored in memory only (verify no accidental logging).
- Auth headers present on protected endpoints.
- Env secrets not committed; `.env` ignored.

## Backend API tests (manual or Postman)
1. `/auth/register` 201 with valid payload.
2. `/auth/login` 200 returns tokens.
3. `/auth/verify-otp` 200 with correct code; 400 with wrong code.
4. `/places` 200, returns list with normalized fields.
5. `/places/search` with params returns filtered list.
6. `/places/recommend` returns recommendations; 401 without token.
7. `/destinations/save` 201; `/destinations/me` returns saved; delete removes.
8. `/places/photo/{id}` returns signed/public URL.

## Regression checklist (quick)
- Login/register works.
- Places search returns data.
- Route planner draws a route (or fallback message).
- Playlists/favourites screens open and list items.
- Theme toggle works.
- No crashes on back navigation.

## Test data
- User: `testuser+1@example.com`, password `Passw0rd!`.
- Places: use known ids from Supabase seed (e.g., `123`, `456`).
- OTP: configure backend to use deterministic test code in staging.

## Automation ideas (future)
- Flutter integration tests for auth flow and search.
- Backend pytest for each endpoint with Supabase test schema.
- Contract tests ensuring field names match app expectations.

