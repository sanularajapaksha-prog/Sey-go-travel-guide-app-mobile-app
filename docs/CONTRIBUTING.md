# Contributing Guide

Welcome! This repo hosts both the Flutter client and FastAPI backend for SeyGo. Follow the steps below to contribute safely and consistently.

## Branching strategy
- `main` is protected; create feature branches off latest `origin/main`.
- Suggested prefixes: `feat/`, `fix/`, `chore/`, `docs/`, `test/`.
- Keep branches short-lived; rebase or merge (no strict policy—keep history clean).

## Commit messages
- Use imperative, short summary: `feat: add offline cache for places`
- Group related changes; avoid “misc fixes”.
- Include docs/tests updates in the same commit when applicable.

## Code style
- Flutter/Dart: follow `analysis_options.yaml` (run `flutter format` and `flutter analyze`).
- Python: `black` + `ruff` (if installed). Pydantic/FastAPI style: type hints everywhere.
- Keep functions small; favor clarity over cleverness.

## Front-end workflow
1) `cd Documents/seygo/front-end`
2) `flutter pub get`
3) `flutter analyze` and `flutter test`
4) For Android emulator, set `.env` with `API_BASE_URL=http://10.0.2.2:8000`
5) For iOS/web/macOS, use `http://127.0.0.1:8000`

## Backend workflow
1) `cd Documents/seygo/backend`
2) `cp .env.example .env` and fill Supabase keys
3) `pip install -r requirements.txt`
4) `uvicorn app.main:app --reload --port 8000`
5) Run tests (when added) with `pytest`

## Pull request checklist
- [ ] Tests pass (`flutter test` / `pytest`)
- [ ] `flutter analyze` passes
- [ ] `.env.example` updated if new env vars were added
- [ ] Screenshots for UI-visible changes (attach to PR)
- [ ] No secrets committed (double-check git diff)
- [ ] Docs updated (README/CHANGELOG/Architecture)

## Coding patterns (Flutter)
- Keep API calls inside `lib/data/services/`.
- Use Providers for app-wide state (theme, font, auth, favorites).
- Extract widgets for repeated UI (cards, popups, buttons).
- Handle loading/error states; avoid silent failures.
- Avoid blocking UI with long awaits; show progress indicators.

## Coding patterns (FastAPI)
- Put request/response models in `app/schemas/`.
- Keep Supabase interactions inside `app/services/`.
- Validate incoming payloads; return structured errors.
- Use dependency injection for auth (`get_current_user`).
- Keep endpoints lean—heavy lifting goes to services.

## Testing ideas
- Auth happy/invalid path (register/login/verify/resend).
- Places search with and without geolocation.
- Route planner: backend success + client fallback.
- Favorites/playlists CRUD (when wired to backend).

## Documentation
- Update `README.md` and relevant docs when adding features.
- Prefer short, actionable examples (curl + response).

## Releases
- Tag releases as `vX.Y.Z` after CI passes.
- Update `CHANGELOG.md` with highlights.

## Code review tips
- Comment on reasoning, not just code.
- Keep PRs under ~300 lines diff when possible.
- Respond to feedback promptly; resolve conversations when addressed.

