# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ReadWhere is a cross-platform e-reader Flutter application for open formats. It supports EPUB reading with a plugin-based architecture for format extensibility.

## Setup

@docs/0-setup/development.md

## Development Commands

```bash
# Run the app
flutter run

# Run on specific platform
flutter run -d macos
flutter run -d ios
flutter run -d android
flutter run -d chrome

# Build
flutter build macos
flutter build ios
flutter build apk

# Analysis and linting
flutter analyze
dart analyze

# Run tests
flutter test
flutter test test/widget_test.dart  # Single test file

# Generate code (for mockito mocks)
dart run build_runner build

# Get dependencies
flutter pub get
```

## Architecture

The app follows **Clean Architecture** with a clear separation of concerns:

```
lib/
├── core/           # Shared utilities, DI, constants, extensions, errors
├── data/           # Data layer: database, repositories impl, models, sources
├── domain/         # Business logic: entities, repository interfaces, use cases
├── plugins/        # Reader plugin system for format support
├── presentation/   # UI layer: providers, screens, widgets, themes, router
└── scripting/      # Lua scripting bindings for extensibility
```

### Key Architectural Patterns

1. **Dependency Injection**: Uses `get_it` package. Service locator at `lib/core/di/service_locator.dart`. Call `setupServiceLocator()` at app startup.

2. **State Management**: Provider pattern with `ChangeNotifier`. Main providers:
   - `LibraryProvider` - Book library state
   - `ReaderProvider` - Reading session state
   - `SettingsProvider` - App settings with SharedPreferences persistence
   - `ThemeProvider` - Theme management

3. **Navigation**: Uses `go_router` configured in `lib/presentation/router/`

4. **Plugin System**: Extensible reader plugins in `lib/plugins/`:
   - `ReaderPlugin` - Abstract interface for format support
   - `ReaderController` - Reading session controller
   - `PluginRegistry` - Singleton plugin manager
   - Currently implements EPUB support in `lib/plugins/epub/`

### Data Flow

```
UI (Screens/Widgets)
    ↓ (Consumer/Provider)
Providers (ChangeNotifier)
    ↓ (Repository interface)
Domain Repositories (abstract)
    ↓ (implementation)
Data Repositories (concrete)
    ↓
Database/Sources
```

## Key Dependencies

- **UI**: `google_fonts`, `flutter_svg`, `macos_ui` (macOS-specific)
- **EPUB**: `epubx`, `flutter_html`, `archive`
- **Storage**: `sqflite`, `shared_preferences`, `path_provider`
- **Scripting**: `lua_dardo_co` for Lua plugin scripting
- **Content Sources**: `dart_rss` for RSS/Atom feeds

## Commit Guidelines

Use semantic commits (e.g., `feat:`, `fix:`, `chore:`, `refactor:`).
