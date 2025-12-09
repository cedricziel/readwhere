# ReadWhere

A cross-platform e-reader Flutter application for open formats.

## Features

- **EPUB Support** - Read EPUB e-books with full navigation and styling
- **Comic Support** - CBZ, CBR, CB7, CBT comic archive formats
- **OPDS Catalogs** - Browse and download from OPDS feeds
- **Kavita Integration** - Connect to Kavita servers
- **Cross-Platform** - macOS, iOS, Android, Web

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run on specific platform
flutter run -d macos
flutter run -d chrome
```

## Development

### Running Tests

```bash
# Run all tests
flutter test

# Run package tests
dart test -p packages/readwhere_epub
```

### Sample Test Media

The project includes a dev package for downloading sample test files:

```bash
# Download sample EPUB, CBZ, CBR, PDF files for testing
dart run readwhere_sample_media:download
```

This downloads ~10 MB of sample files to `.dart_tool/sample_media/` for integration testing. Files are cached and won't re-download unless the version changes.

Use in tests:

```dart
import 'package:readwhere_sample_media/readwhere_sample_media.dart';

final epubs = SampleMediaPaths.epubFiles;
final cbzFiles = SampleMediaPaths.cbzFiles;
```

### Project Structure

```
lib/
├── core/           # DI, constants, extensions, errors
├── data/           # Repositories, models, database
├── domain/         # Entities, repository interfaces, use cases
├── plugins/        # Reader plugin system for format support
├── presentation/   # Providers, screens, widgets
└── scripting/      # Lua scripting bindings

packages/
├── readwhere_epub/           # EPUB 3.3 parsing library
├── readwhere_cbz/            # CBZ comic archive support
├── readwhere_cbr/            # CBR comic archive support
├── readwhere_rar/            # RAR 4.x decompression
├── readwhere_sample_media/   # Test media downloader
└── ...
```

## License

See [LICENSE](LICENSE) for details.
