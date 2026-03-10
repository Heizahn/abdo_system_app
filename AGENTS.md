# AGENTS.md — abdo_system_app

Flutter mobile application ("SISTEMA ABDO77") for ISP client management.
Dart SDK ^3.11.0, Material 3, Provider state management, GoRouter navigation.

## Build & Run Commands

```bash
# Get dependencies (run after pubspec.yaml changes)
flutter pub get

# Run the app (debug)
flutter run

# Build release APK
flutter build apk --release

# Build release app bundle
flutter build appbundle --release

# Static analysis (linting)
flutter analyze

# Format all Dart files (line length 80, the Dart default)
dart format .

# Format check only (CI-friendly, exits non-zero if changes needed)
dart format --set-exit-if-changed .
```

## Testing

```bash
# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Run tests matching a name pattern
flutter test --name "some test description"

# Run with coverage
flutter test --coverage
```

Note: The test suite is minimal (only `test/widget_test.dart` exists and tests the
default counter app, not the actual application). New features should include tests.

## Environment Setup

- Requires a `.env` file in the project root with at minimum `API_URL`.
- The `.env` file is gitignored. Never commit secrets or environment files.
- Environment variables are loaded via `flutter_dotenv` in `lib/config/env_config.dart`.

## Project Architecture

```
lib/
  main.dart              # Entry point, MultiProvider setup
  config/                # Environment config, role definitions
  models/                # Data classes with fromJson factories
  providers/             # ChangeNotifier state management classes
  services/              # API client (Dio singleton), auth service
  router/                # GoRouter config with role-based route protection
  screens/               # Top-level screen widgets
  components/            # Reusable UI components organized by feature
  layouts/               # Shell layouts (MainLayout with tab navigation)
  theme/                 # Material 3 theme definitions (light + dark)
  utils/                 # Utility/helper classes (formatters)
  assets/                # SVG/PNG assets bundled with the app
```

### Key Architectural Patterns

- **State management**: `provider` package with `ChangeNotifier`. All providers are
  registered in `main.dart` via `MultiProvider`.
- **Routing**: `go_router` with async redirect guards. Role-based access control is
  defined in `lib/config/roles.dart`.
- **HTTP**: `dio` singleton in `lib/services/api_client.dart` with interceptors for
  auth token injection and automatic token refresh on 401.
- **Auth**: JWT tokens stored in `flutter_secure_storage`. Token refresh flow with
  "keep session" logic handled by interceptors.
- **Models**: Plain Dart classes with `factory Model.fromJson(Map<String, dynamic>)`
  constructors (manual JSON serialization, no code generation).

## Code Style Guidelines

### Language

- UI text, comments, and variable documentation are in **Spanish**.
- Class names, method names, and identifiers follow standard **English** Dart
  conventions (e.g., `ClientStatus`, `loadUser`, `formatAmount`), but domain-specific
  enum values may be in Spanish (e.g., `ClientStatus.solvente`, `ClientStatus.moroso`).

### Dart/Flutter Conventions

- **Linting**: `package:flutter_lints/flutter.yaml` (configured in `analysis_options.yaml`).
  Run `flutter analyze` and fix all warnings before committing.
- **Formatting**: Standard `dart format` (80-char line width). Always format before committing.
- **Trailing commas**: Use trailing commas on all argument lists and collection literals
  that span multiple lines. This ensures `dart format` produces clean diffs.

### Imports

- Group imports in this order, separated by a blank line:
  1. Dart SDK (`dart:...`)
  2. Flutter framework (`package:flutter/...`)
  3. Third-party packages (`package:dio/...`, `package:provider/...`, etc.)
  4. Project-local package imports (`package:abdo_system_app/...`)
  5. Relative imports (`../`, `./`)
- Prefer **relative imports** for intra-library references within `lib/` (this is the
  existing convention in most files). Some files use package imports — either form is
  acceptable but stay consistent within a single file.
- Never mix relative and package imports in the same file.

### Naming

- **Classes**: `UpperCamelCase` — `ClientProvider`, `ApiClient`, `AppTheme`
- **Files**: `snake_case.dart` — `client_model.dart`, `api_client.dart`
- **Variables/methods**: `lowerCamelCase` — `isLoading`, `loadUser()`, `formatAmount()`
- **Constants**: `lowerCamelCase` for top-level and static constants — `static const double superadmin = 0`
- **Private members**: Prefix with `_` — `_user`, `_isLoading`, `_statusColor()`
- **Private widgets**: Prefix class name with `_` — `class _Avatar extends StatelessWidget`
- **Enums**: `UpperCamelCase` for the type, `lowerCamelCase` for values — `ClientStatus.solvente`

### Types & Models

- Always declare explicit types for class fields, method parameters, and return types.
- Models are plain Dart classes with `const` constructors where possible, `required`
  named parameters, and `factory Model.fromJson(Map<String, dynamic> json)` factories.
- Handle null API responses defensively with `as Type?` casts and `?? defaultValue` fallbacks
  (see `Client.fromJson` for the pattern).
- Use `num.toDouble()` when the API may return int or double for numeric fields.

### Widgets

- Prefer `StatelessWidget` with `const` constructors unless local mutable state is needed.
- Use `super.key` in constructors (not `Key? key`).
- Access theme via `Theme.of(context)` stored in a local variable at the top of `build()`.
- Access custom theme extensions: `theme.extension<AppColors>()!.success`.
- Use `RepaintBoundary` for list items and complex cards to optimize rendering.
- Extract private helper widgets (prefixed with `_`) in the same file for readability.

### State Management (Provider)

- Each provider extends `ChangeNotifier`.
- Private state with public getters: `Type _field; Type get field => _field;`.
- Call `notifyListeners()` after state changes.
- Use `context.watch<T>()` in `build()` for reactive rebuilds.
- Use `context.read<T>()` for one-off access (event handlers, callbacks).

### Error Handling

- Wrap async operations in `try/catch/finally`; use `finally` for cleanup (e.g., setting
  `_isLoading = false` and calling `notifyListeners()`).
- HTTP errors: The Dio interceptor handles 401 (auto-refresh). Other errors propagate to
  the provider layer for UI handling.
- Use `print()` for debug logging (the project does not yet use a structured logger).
- Never silently swallow exceptions — at minimum log them.

### Theme & Styling

- Material 3 enabled (`useMaterial3: true`).
- Light and dark themes defined in `lib/theme/app_theme.dart`.
- Semantic colors via `ThemeExtension<AppColors>` (currently: `success`).
- Use `colorScheme.tertiary` for info, `colorScheme.outline` for warning.
- Use `withValues(alpha: x)` (not deprecated `withOpacity`) for transparency.
- Standard border radius: 12–14px. Elevation: 0 (flat Material 3 style).

### Routing

- All routes defined in `lib/router/app_router.dart`.
- Route protection via `redirect:` with role-based access from `lib/config/roles.dart`.
- Use `context.go('/path')` for navigation, `context.push('/path')` for stack navigation.
- Parameterized routes: `/client/:id` — access via `state.pathParameters['id']`.
