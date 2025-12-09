import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../storage/plugin_storage.dart';

/// Context provided to plugins during initialization.
///
/// Contains references to storage, services, and configuration
/// that plugins may need during their lifecycle.
///
/// The context is created by the plugin registry and passed to
/// [PluginBase.initialize] when a plugin is registered.
class PluginContext {
  /// Storage scoped to the plugin.
  ///
  /// Provides access to settings, credentials, and cache storage.
  /// All data is automatically namespaced to the plugin's ID.
  final PluginStorage storage;

  /// HTTP client for network requests.
  ///
  /// Use this for all HTTP operations to benefit from shared
  /// configuration (timeouts, interceptors, etc.).
  final http.Client httpClient;

  /// Logger for this plugin.
  ///
  /// Pre-configured with the plugin's name for easy identification
  /// in logs.
  final Logger logger;

  /// App-wide configuration.
  ///
  /// Contains information about the app environment that plugins
  /// may need to adapt their behavior.
  final PluginAppConfig appConfig;

  /// Callback to request provider refresh.
  ///
  /// Call this when the plugin's state has changed and the UI
  /// needs to update. This triggers a rebuild of widgets that
  /// depend on the plugin's providers.
  final VoidCallback? onProviderStateChanged;

  /// Directory for plugin-specific files.
  ///
  /// Plugins can store any files they need here. The directory
  /// is created if it doesn't exist and is scoped to the plugin.
  final Directory pluginDataDirectory;

  /// Directory for downloaded content.
  ///
  /// Use this for downloaded books and other content files.
  /// This may be a shared directory across plugins.
  final Directory downloadDirectory;

  /// Creates a new plugin context.
  const PluginContext({
    required this.storage,
    required this.httpClient,
    required this.logger,
    required this.appConfig,
    this.onProviderStateChanged,
    required this.pluginDataDirectory,
    required this.downloadDirectory,
  });

  /// Notify the system that provider state has changed.
  ///
  /// Convenience method that safely calls [onProviderStateChanged]
  /// if it's not null.
  void notifyStateChanged() {
    onProviderStateChanged?.call();
  }
}

/// Void callback type for state change notifications.
typedef VoidCallback = void Function();

/// App-wide configuration accessible to plugins.
///
/// Contains information about the app environment that plugins
/// may need to adapt their behavior (e.g., platform-specific logic,
/// locale-aware formatting, theme-aware icons).
class PluginAppConfig {
  /// App version string (e.g., '1.2.3').
  final String appVersion;

  /// Platform identifier.
  ///
  /// One of: 'ios', 'android', 'macos', 'windows', 'linux', 'web'
  final String platform;

  /// User-preferred locale (e.g., 'en_US', 'de_DE').
  final String locale;

  /// Whether dark mode is currently enabled.
  final bool isDarkMode;

  /// User agent string for HTTP requests.
  ///
  /// Plugins should use this when making HTTP requests to
  /// properly identify the app.
  final String userAgent;

  /// Creates a new app configuration.
  const PluginAppConfig({
    required this.appVersion,
    required this.platform,
    required this.locale,
    required this.isDarkMode,
    String? userAgent,
  }) : userAgent = userAgent ?? 'ReadWhere/$appVersion ($platform)';

  /// Whether the app is running on a mobile platform.
  bool get isMobile => platform == 'ios' || platform == 'android';

  /// Whether the app is running on a desktop platform.
  bool get isDesktop =>
      platform == 'macos' || platform == 'windows' || platform == 'linux';

  /// Whether the app is running in a web browser.
  bool get isWeb => platform == 'web';

  @override
  String toString() =>
      'PluginAppConfig('
      'appVersion: $appVersion, '
      'platform: $platform, '
      'locale: $locale, '
      'isDarkMode: $isDarkMode'
      ')';
}

/// Factory for creating plugin contexts.
///
/// Implementations provide the actual context creation logic,
/// which may involve platform-specific setup.
abstract class PluginContextFactory {
  /// Create a context for the given plugin.
  ///
  /// [pluginId] is used to scope storage and logging.
  /// [storage] is the pre-created storage instance for the plugin.
  Future<PluginContext> create(String pluginId, PluginStorage storage);
}
