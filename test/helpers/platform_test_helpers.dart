import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Standard platform groupings for testing adaptive widgets.
///
/// Use these to run tests across platform categories:
/// - [cupertino] for iOS/macOS (uses CupertinoActionSheet, etc.)
/// - [material] for Android/Linux/Windows (uses Material widgets)
class TestPlatforms {
  TestPlatforms._();

  /// Platforms that use Cupertino-style widgets (iOS, macOS)
  static const List<TargetPlatform> cupertino = [
    TargetPlatform.iOS,
    TargetPlatform.macOS,
  ];

  /// Platforms that use Material-style widgets (Android, Linux, Windows)
  static const List<TargetPlatform> material = [
    TargetPlatform.android,
    TargetPlatform.linux,
    TargetPlatform.windows,
  ];

  /// All supported platforms
  static List<TargetPlatform> get all => TargetPlatform.values.toList();
}

/// Runs a widget test on a specific platform.
///
/// The platform name is appended to the test description for clarity.
///
/// Example:
/// ```dart
/// testWidgetsOnPlatform('shows dialog', TargetPlatform.iOS, (tester) async {
///   // test code runs with iOS platform behavior
/// });
/// ```
void testWidgetsOnPlatform(
  String description,
  TargetPlatform platform,
  WidgetTesterCallback callback,
) {
  testWidgets('$description (${platform.name})', (tester) async {
    debugDefaultTargetPlatformOverride = platform;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await callback(tester);
  });
}

/// Runs a widget test on multiple platforms.
///
/// Creates separate test cases for each platform in the list.
///
/// Example:
/// ```dart
/// testWidgetsOnPlatforms(
///   'renders correctly',
///   [TargetPlatform.iOS, TargetPlatform.android],
///   (tester) async {
///     // test runs twice, once for each platform
///   },
/// );
/// ```
void testWidgetsOnPlatforms(
  String description,
  List<TargetPlatform> platforms,
  WidgetTesterCallback callback,
) {
  for (final platform in platforms) {
    testWidgetsOnPlatform(description, platform, callback);
  }
}

/// Runs a widget test on all supported platforms.
///
/// Creates separate test cases for iOS, macOS, Android, Linux, Windows, and Fuchsia.
///
/// Example:
/// ```dart
/// testWidgetsOnAllPlatforms('basic rendering works', (tester) async {
///   // test runs 6 times, once per platform
/// });
/// ```
void testWidgetsOnAllPlatforms(
  String description,
  WidgetTesterCallback callback,
) {
  testWidgetsOnPlatforms(description, TestPlatforms.all, callback);
}

/// Runs a widget test on Cupertino platforms (iOS, macOS).
///
/// Use this for testing widgets that use [context.useCupertino] or
/// platform-adaptive widgets like [AdaptiveActionSheet].
///
/// Example:
/// ```dart
/// testWidgetsOnCupertino('shows CupertinoActionSheet', (tester) async {
///   // test runs on iOS and macOS
/// });
/// ```
void testWidgetsOnCupertino(
  String description,
  WidgetTesterCallback callback,
) {
  testWidgetsOnPlatforms(description, TestPlatforms.cupertino, callback);
}

/// Runs a widget test on Material platforms (Android, Linux, Windows).
///
/// Use this for testing widgets that use Material Design on non-Apple platforms.
///
/// Example:
/// ```dart
/// testWidgetsOnMaterial('shows Material bottom sheet', (tester) async {
///   // test runs on Android, Linux, and Windows
/// });
/// ```
void testWidgetsOnMaterial(
  String description,
  WidgetTesterCallback callback,
) {
  testWidgetsOnPlatforms(description, TestPlatforms.material, callback);
}
