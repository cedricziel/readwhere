# Suggested Commands

## Development
```bash
flutter run                    # Run the app (default device)
flutter run -d macos          # Run on macOS
flutter run -d ios            # Run on iOS
flutter run -d android        # Run on Android
flutter run -d chrome         # Run on web
```

## Building
```bash
flutter build macos           # Build for macOS
flutter build ios             # Build for iOS
flutter build apk             # Build Android APK
```

## Analysis & Testing
```bash
flutter analyze               # Static analysis
dart analyze                  # Dart analysis
flutter test                  # Run all tests
flutter test test/widget_test.dart  # Single test file
```

## Code Generation
```bash
dart run build_runner build   # Generate mocks for mockito
```

## Dependencies
```bash
flutter pub get               # Get dependencies
```

## Utility Commands (macOS/Darwin)
```bash
git status                    # Check git status
ls -la                        # List files
find . -name "*.dart"        # Find Dart files
grep -r "pattern" lib/       # Search in lib
```
