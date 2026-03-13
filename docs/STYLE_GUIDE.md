# Style Guide

## Dart/Flutter
- Use `final` by default; prefer `const` widgets when possible.
- Keep widgets small; extract UI chunks >40 lines.
- Name widgets with intent: `DestinationCard`, `FavoritesProvider`.
- Avoid global mutable state; use Providers.
- Handle nulls explicitly; avoid `!` unless proven safe.
- Prefer `SizedBox(height: ...)` over `Container` when only spacing.
- Keep imports ordered: Flutter, third-party, project.
- Use trailing commas to preserve formatting.
- Avoid deeply nested widgets—extract builders.

## API usage
- Centralize HTTP in `ApiService`; no raw http in widgets.
- Always set `Content-Type: application/json`.
- Handle non-200 with user-friendly messages.
- Reuse `baseUrl` getter; no hard-coded URLs.

## Theming
- Colors defined in `lib/theme/app_theme.dart`.
- Do not inline hex colors in widgets.
- Respect light/dark modes; test both.
- Text styles via theme extensions or `app_export.dart`.

## Naming
- Classes: PascalCase (`RoutePlannerScreen`).
- Files: snake_case (`route_planner_screen.dart`).
- Constants: lowerCamelCase or ALL_CAPS if global.
- Private helpers with leading underscore.

## Layout
- Use `SafeArea` for top-level pages.
- Scrollable screens use `SingleChildScrollView` or `CustomScrollView`.
- Forms: use `TextFormField` with validators; show errors inline.

## Error handling
- Catch and surface network errors (SnackBar/Toast).
- Log unexpected exceptions during dev; avoid print spam in prod.

## Accessibility
- Minimum tap targets 44x44.
- Support text scaling; avoid fixed font sizes where possible.
- Provide semantic labels for icons important to navigation.

## Backend (Python)
- Type hints everywhere.
- Pydantic models in `schemas`; keep routers thin.
- Use `Depends` for auth; avoid direct env reads inside handlers.
- Handle Supabase errors; return clear HTTP status codes.
- Keep functions small; prefer pure helpers in `services`.

## Git hygiene
- No secrets in commits. `.env`, `.flutter-plugins-dependencies`, `*.xcconfig` are ignored.
- One logical change per commit; include tests/docs when relevant.
- Run `flutter analyze` / `flutter test` before PRs.

