# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ReadWhere is a cross-platform e-reader Flutter application for open formats. It supports EPUB, CBZ, CBR comics, and integrates with OPDS catalogs and Kavita servers via a plugin-based architecture.

## Context

@docs/0-setup/development.md contains setup instructions.
@docs/0-setup/ux.md contains UX guidelines.
@docs/0-setup/plugins-packages.md describes the plugin/package architecture.

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
flutter test                                    # Main app tests
dart test packages/readwhere_epub/              # EPUB package tests

# Run single test file
flutter test test/widget_test.dart
dart test packages/readwhere_epub/test/validation/epub_validator_test.dart

# Run package tests (from package directory)
cd packages/readwhere_nextcloud && flutter test

# Generate mocks
dart run build_runner build

# Download sample test media for integration testing
dart run readwhere_sample_media:download

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

The app uses a two-tier plugin architecture:

**Format packages** (pure Dart, no Flutter dependencies):

- `readwhere_epub`, `readwhere_cbz`, `readwhere_cbr`, `readwhere_rar` - Format parsing
- `readwhere_opds`, `readwhere_kavita`, `readwhere_nextcloud` - Catalog protocols
- `readwhere_rss`, `readwhere_fanfictionde` - Content sources

**Plugins** (bridge packages to app via `readwhere_plugin` interfaces):

- Reader plugins: `readwhere_epub_plugin`, `readwhere_cbz_plugin`, `readwhere_cbr_plugin`
- Catalog plugins: `readwhere_opds_plugin`, `readwhere_kavita_plugin`, `readwhere_rss_plugin`, `readwhere_fanfictionde_plugin`

Key interfaces:

- `ReaderPlugin` - `canHandle()`, `parseMetadata()`, `openBook()`, `extractCover()`
- `CatalogBrowsingCapability` - Unified catalog browsing for OPDS, Kavita, RSS
- `UnifiedPluginRegistry` - Registry integrated with service locator
- `ReaderController` - Reading session state

### State Management

Provider pattern with `ChangeNotifier`:

- `LibraryProvider` - Book library state
- `ReaderProvider` - Reading session state
- `SettingsProvider` - Persisted app settings (SharedPreferences)
- `ThemeProvider` - Theme management

### Dependency Injection

Uses `get_it` package. Service locator at `lib/core/di/service_locator.dart`. Call `setupServiceLocator()` at app startup.

## Workspace Structure

This is a Dart workspace with multiple packages under `packages/`:

**Format Libraries** (pure Dart):

- `readwhere_epub` - EPUB 3.3 parsing
- `readwhere_cbz`, `readwhere_cbr`, `readwhere_rar` - Comic archives

**Catalog/Protocol Libraries**:

- `readwhere_opds` - OPDS catalog protocol
- `readwhere_kavita` - Kavita server API
- `readwhere_nextcloud`, `readwhere_webdav` - Nextcloud/WebDAV
- `readwhere_rss`, `readwhere_opml` - RSS feeds
- `readwhere_fanfictionde` - Fanfiction.de scraper

**Plugins** (bridge libraries to app):

- `readwhere_plugin` - Base interfaces
- `readwhere_*_plugin` - Format/catalog-specific implementations

**Utilities**:

- `readwhere_panel_detection` - Comic panel detection
- `readwhere_sample_media` - Test media downloader

Pure Dart packages use `test` package (not `flutter_test`) and have their own test suites.

## Sample Test Media

The `readwhere_sample_media` package downloads sample EPUB, CBZ, CBR, PDF files for integration testing:

```bash
dart run readwhere_sample_media:download
```

Files are cached in `.dart_tool/sample_media/` (~10 MB). Use in tests:

```dart
import 'package:readwhere_sample_media/readwhere_sample_media.dart';

final epubs = SampleMediaPaths.epubFiles;
final cbzFiles = SampleMediaPaths.cbzFiles;
```

## Test Coverage

Target: 80% coverage. The EPUB package has comprehensive tests (~700+). Run coverage:

```bash
cd packages/readwhere_epub
dart test --coverage=coverage
```

## Commit Guidelines

Use semantic commits: `feat:`, `fix:`, `chore:`, `refactor:`, `docs:`, `test:`
