# ReadWhere Project Overview

## Purpose
Cross-platform e-reader Flutter application for open formats (EPUB, etc.)

## Tech Stack
- **Framework**: Flutter (Dart)
- **State Management**: Provider with ChangeNotifier
- **Navigation**: go_router
- **Database**: SQLite (sqflite)
- **Storage**: SharedPreferences, path_provider
- **EPUB**: epubx, flutter_html, archive, xml
- **Scripting**: lua_dardo_co (Lua plugin extensibility)
- **DI**: get_it

## Architecture
Clean Architecture with separation of concerns:
- `lib/core/` - Shared utilities, DI, constants, extensions, errors
- `lib/data/` - Data layer: database, repositories impl, models, sources
- `lib/domain/` - Business logic: entities, repository interfaces, use cases
- `lib/plugins/` - Reader plugin system for format support
- `lib/presentation/` - UI layer: providers, screens, widgets, themes, router
- `lib/scripting/` - Lua scripting bindings

## Key Patterns
1. Dependency Injection via get_it (service_locator.dart)
2. Provider pattern with ChangeNotifier for state
3. Clean Architecture (data → domain → presentation)
4. Plugin system for extensible format support
