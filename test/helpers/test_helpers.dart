import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readwhere/domain/entities/book.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';

export 'platform_test_helpers.dart';

/// Creates a MaterialApp wrapper for widget testing
///
/// Wraps the provided [child] widget in a MaterialApp with optional
/// [theme] and [screenSize] configurations.
Widget buildTestableWidget(
  Widget child, {
  ThemeData? theme,
  Size? screenSize,
  NavigatorObserver? navigatorObserver,
}) {
  Widget widget = MaterialApp(
    theme: theme ?? ThemeData.light(),
    home: child,
    navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
  );

  if (screenSize != null) {
    widget = wrapWithMediaQuery(widget, screenSize);
  }

  return widget;
}

/// Creates a MediaQuery wrapper for responsive testing
///
/// Wraps the provided [child] widget with a MediaQuery that reports
/// the given [size] as the screen size.
Widget wrapWithMediaQuery(Widget child, Size size) {
  return MediaQuery(
    data: MediaQueryData(size: size),
    child: child,
  );
}

/// Creates a test Book fixture with sensible defaults
///
/// All parameters are optional and will use default test values if not provided.
Book createTestBook({
  String id = 'test-book-id',
  String title = 'Test Book Title',
  String author = 'Test Author',
  String filePath = '/path/to/test/book.epub',
  String? coverPath,
  String format = 'epub',
  int fileSize = 1024000,
  DateTime? addedAt,
  DateTime? lastOpenedAt,
  bool isFavorite = false,
  double? readingProgress,
  EpubEncryptionType encryptionType = EpubEncryptionType.none,
  bool isFixedLayout = false,
  bool hasMediaOverlays = false,
  String? sourceCatalogId,
  String? sourceEntryId,
}) {
  return Book(
    id: id,
    title: title,
    author: author,
    filePath: filePath,
    coverPath: coverPath,
    format: format,
    fileSize: fileSize,
    addedAt: addedAt ?? DateTime(2024, 1, 1),
    lastOpenedAt: lastOpenedAt,
    isFavorite: isFavorite,
    readingProgress: readingProgress,
    encryptionType: encryptionType,
    isFixedLayout: isFixedLayout,
    hasMediaOverlays: hasMediaOverlays,
    sourceCatalogId: sourceCatalogId,
    sourceEntryId: sourceEntryId,
  );
}

/// Creates multiple test books with unique IDs
///
/// Returns a list of [count] test books with incremental IDs and titles.
List<Book> createTestBooks(int count) {
  return List.generate(
    count,
    (index) => createTestBook(
      id: 'test-book-$index',
      title: 'Test Book ${index + 1}',
      author: 'Author ${index + 1}',
    ),
  );
}

/// Creates a test Book with reading progress
Book createTestBookWithProgress({
  String id = 'test-book-progress',
  double progress = 0.5,
}) {
  return createTestBook(
    id: id,
    title: 'Book In Progress',
    readingProgress: progress,
    lastOpenedAt: DateTime.now(),
  );
}

/// Creates a test Book marked as favorite
Book createTestFavoriteBook({String id = 'test-book-favorite'}) {
  return createTestBook(id: id, title: 'Favorite Book', isFavorite: true);
}

/// Creates a test Book with DRM encryption
Book createTestDrmBook({
  String id = 'test-book-drm',
  EpubEncryptionType encryptionType = EpubEncryptionType.adobeDrm,
}) {
  return createTestBook(
    id: id,
    title: 'DRM Protected Book',
    encryptionType: encryptionType,
  );
}

/// Standard screen sizes for responsive testing
class TestScreenSizes {
  TestScreenSizes._();

  /// Mobile phone screen (iPhone SE size)
  static const Size mobile = Size(375, 667);

  /// Mobile phone screen (larger, iPhone 13/14 size)
  static const Size mobileLarge = Size(390, 844);

  /// Mobile phone screen (iPhone 13/14 Pro Max)
  static const Size mobileXLarge = Size(414, 896);

  /// Tablet screen (iPad)
  static const Size tablet = Size(768, 1024);

  /// Desktop screen
  static const Size desktop = Size(1440, 900);

  /// Small desktop/laptop
  static const Size desktopSmall = Size(1280, 800);

  /// Breakpoint just below tablet threshold (< 600)
  static const Size belowTablet = Size(599, 800);

  /// Breakpoint just above tablet threshold (>= 600)
  static const Size atTablet = Size(600, 800);

  /// Breakpoint just below desktop threshold (< 1200)
  static const Size belowDesktop = Size(1199, 800);

  /// Breakpoint just at desktop threshold (>= 1200)
  static const Size atDesktop = Size(1200, 800);

  /// Default test size - iPhone 13 dimensions
  static const Size defaultTest = Size(375, 812);
}

/// Sets a consistent test screen size for the duration of the test.
///
/// This helps avoid layout issues that occur due to different default
/// screen sizes on different CI platforms (e.g., Linux vs macOS).
///
/// Example:
/// ```dart
/// testWidgets('context menu fits on screen', (tester) async {
///   await setTestScreenSize(tester);
///   // test code...
/// });
/// ```
Future<void> setTestScreenSize(
  WidgetTester tester, {
  Size size = TestScreenSizes.defaultTest,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

/// Sets up both platform and screen size for a test.
///
/// Convenience method that combines platform override with screen size setup.
///
/// Example:
/// ```dart
/// testWidgets('shows iOS layout on phone', (tester) async {
///   await setupTestEnvironment(
///     tester,
///     platform: TargetPlatform.iOS,
///     screenSize: TestScreenSizes.mobile,
///   );
///   // test code...
/// });
/// ```
Future<void> setupTestEnvironment(
  WidgetTester tester, {
  TargetPlatform? platform,
  Size? screenSize,
}) async {
  if (platform != null) {
    debugDefaultTargetPlatformOverride = platform;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
  }
  if (screenSize != null) {
    await setTestScreenSize(tester, size: screenSize);
  }
}
