# Development Guidelines

## Test Coverage

We aim for a minimum of 80% test coverage across the codebase. Please ensure that any new features or bug fixes include appropriate tests to maintain or improve this coverage level.

## Test Driven Development (TDD)

We encourage the use of Test Driven Development (TDD) practices. Write your tests before implementing the corresponding functionality to ensure that your code meets the required specifications from the outset.

When encountering bugs, please write tests that reproduce the issue before fixing it. This approach helps to verify that the bug has been resolved and prevents regressions in the future.

## Documentation

Refer to context7 for accurate documentation for libraries and frameworks used in this project. Proper documentation is essential for maintaining code quality and facilitating collaboration among team members.

## Cross-Platform Testing

ReadWhere uses adaptive widgets that render differently on iOS/macOS (Cupertino) vs Android/Linux/Windows (Material). Follow these practices to ensure consistent behavior across platforms.

### Platform Test Helpers

Use the platform test helpers in `test/helpers/platform_test_helpers.dart`:

```dart
// Test on a specific platform
testWidgetsOnPlatform('shows dialog', TargetPlatform.iOS, (tester) async {
  // test code
});

// Test on all Cupertino platforms (iOS, macOS)
testWidgetsOnCupertino('shows action sheet', (tester) async {
  // test code
});

// Test on all Material platforms (Android, Linux, Windows)
testWidgetsOnMaterial('shows bottom sheet', (tester) async {
  // test code
});

// Test on all platforms
testWidgetsOnAllPlatforms('renders correctly', (tester) async {
  // test code
});
```

### Screen Size Consistency

Always set a consistent screen size in tests to avoid layout issues between local development and CI:

```dart
testWidgets('context menu fits on screen', (tester) async {
  await setTestScreenSize(tester); // defaults to 375x812 (iPhone 13)
  // test code
});

// Or use predefined sizes
await setTestScreenSize(tester, size: TestScreenSizes.tablet);
```

### Best Practices

1. **Test both platform paths** for adaptive widgets that branch on `context.useCupertino`
2. **Set explicit screen sizes** to avoid CI/local discrepancies (CI runners often have smaller default surfaces)
3. **Make scrollable containers** for content that might overflow on small screens
4. **Use `TestScreenSizes`** constants for responsive breakpoint testing
