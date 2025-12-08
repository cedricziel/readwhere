# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ReadWhere is a cross-platform e-reader Flutter application for open formats. It supports EPUB reading with a plugin-based architecture for format extensibility.

## Development Commands

```bash
# Run the app
flutter run
flutter run -d macos    # macOS
flutter run -d chrome   # Web

# Build
flutter build macos
flutter build apk

# Analysis (pre-commit runs these automatically)
flutter analyze

# Run all tests
flutter test                              # Main app tests
dart test -p packages/readwhere_epub      # EPUB package tests

# Run single test file
flutter test test/widget_test.dart
dart test packages/readwhere_epub/test/validation/epub_validator_test.dart

# Generate mocks
dart run build_runner build

# Dependencies
flutter pub get
```

## Pre-commit Hook

The project uses `dart_pre_commit` which enforces:
- **format**: Code formatting
- **analyze**: Zero analyzer warnings required
- **outdated**: Dependencies must not be outdated
- **pull-up-dependencies**: Dependencies must use latest compatible versions

Always ensure commits pass the pre-commit hook. Never use `--no-verify`.

## Architecture

The app follows **Clean Architecture**:

```
lib/
├── core/           # DI (get_it), constants, extensions, errors
├── data/           # Repositories impl, models, database (sqflite)
├── domain/         # Entities, repository interfaces, use cases
├── plugins/        # Reader plugin system for format support
├── presentation/   # Providers (ChangeNotifier), screens, widgets, go_router
└── scripting/      # Lua scripting bindings (lua_dardo_co)
```

### Plugin System

Reader plugins provide format support via `lib/plugins/`:
- `ReaderPlugin` - Abstract interface defining `canHandle()`, `parseMetadata()`, `openBook()`, `extractCover()`
- `PluginRegistry` - Singleton for plugin registration/lookup by extension or MIME type
- `ReaderController` - Controls reading session state
- EPUB plugin implementation at `lib/plugins/epub/`

### State Management

Provider pattern with `ChangeNotifier`:
- `LibraryProvider` - Book library state
- `ReaderProvider` - Reading session state
- `SettingsProvider` - Persisted app settings (SharedPreferences)
- `ThemeProvider` - Theme management

### Dependency Injection

Uses `get_it` package. Service locator at `lib/core/di/service_locator.dart`. Call `setupServiceLocator()` at app startup.

## Workspace Structure

This is a Dart workspace with:
- **Main app** (`/`) - Flutter application
- **readwhere_epub** (`packages/readwhere_epub/`) - Pure Dart EPUB 3.3 parsing library

The EPUB package uses `test` package (not `flutter_test`) and has its own test suite.

## Test Coverage

Target: 80% coverage. The EPUB package has comprehensive tests (~700+). Run coverage:
```bash
cd packages/readwhere_epub
dart test --coverage=coverage
```

## Commit Guidelines

Use semantic commits: `feat:`, `fix:`, `chore:`, `refactor:`, `docs:`, `test:`
