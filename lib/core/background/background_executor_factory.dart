import 'dart:io';

import 'background_executor.dart';
import 'platform/android_background_executor.dart';
import 'platform/desktop_background_executor.dart';
import 'platform/ios_background_executor.dart';

/// Factory for creating platform-specific [BackgroundExecutor] instances.
class BackgroundExecutorFactory {
  BackgroundExecutorFactory._();

  /// Create a background executor appropriate for the current platform.
  ///
  /// Returns:
  /// - [AndroidBackgroundExecutor] on Android
  /// - [IosBackgroundExecutor] on iOS
  /// - [DesktopBackgroundExecutor] on macOS, Windows, and Linux
  ///
  /// Throws [UnsupportedError] on unsupported platforms (Web).
  static BackgroundExecutor create() {
    if (Platform.isAndroid) {
      return AndroidBackgroundExecutor();
    } else if (Platform.isIOS) {
      return IosBackgroundExecutor();
    } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      return DesktopBackgroundExecutor();
    } else {
      throw UnsupportedError(
        'Background execution is not supported on this platform',
      );
    }
  }

  /// Check if background execution is supported on the current platform.
  static bool get isSupported {
    return Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isMacOS ||
        Platform.isWindows ||
        Platform.isLinux;
  }

  /// Get the capabilities for the current platform without creating an executor.
  static BackgroundCapabilities get platformCapabilities {
    if (Platform.isAndroid) {
      return BackgroundCapabilities.android;
    } else if (Platform.isIOS) {
      return BackgroundCapabilities.ios;
    } else {
      return BackgroundCapabilities.desktop;
    }
  }
}
