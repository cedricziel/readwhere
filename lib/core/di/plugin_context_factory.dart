import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';

/// Implementation of [PluginContextFactory] for creating plugin contexts.
///
/// Provides each plugin with:
/// - Pre-configured storage instance
/// - HTTP client for network requests
/// - Logger scoped to the plugin
/// - App configuration
/// - Directories for plugin data and downloads
class PluginContextFactoryImpl implements PluginContextFactory {
  final PluginAppConfig _appConfig;
  Directory? _pluginDataDir;
  Directory? _downloadDir;

  /// Creates a plugin context factory.
  PluginContextFactoryImpl({required PluginAppConfig appConfig})
    : _appConfig = appConfig;

  /// Creates a plugin context factory with app info.
  ///
  /// Convenience constructor that builds [PluginAppConfig] from parameters.
  factory PluginContextFactoryImpl.withConfig({
    required String appVersion,
    required String platform,
    required String locale,
    required bool isDarkMode,
  }) {
    return PluginContextFactoryImpl(
      appConfig: PluginAppConfig(
        appVersion: appVersion,
        platform: platform,
        locale: locale,
        isDarkMode: isDarkMode,
      ),
    );
  }

  /// Ensures directories are initialized.
  Future<void> _ensureDirectories() async {
    if (_pluginDataDir == null) {
      final appDir = await getApplicationSupportDirectory();
      _pluginDataDir = Directory('${appDir.path}/plugins');
      if (!await _pluginDataDir!.exists()) {
        await _pluginDataDir!.create(recursive: true);
      }
    }

    if (_downloadDir == null) {
      final downloadsDir = await getDownloadsDirectory();
      _downloadDir = downloadsDir ?? await getTemporaryDirectory();
    }
  }

  @override
  Future<PluginContext> create(String pluginId, PluginStorage storage) async {
    await _ensureDirectories();

    // Create plugin-specific data directory
    final pluginDataDir = Directory('${_pluginDataDir!.path}/$pluginId');
    if (!await pluginDataDir.exists()) {
      await pluginDataDir.create(recursive: true);
    }

    return PluginContext(
      storage: storage,
      httpClient: http.Client(),
      logger: Logger(pluginId),
      appConfig: _appConfig,
      pluginDataDirectory: pluginDataDir,
      downloadDirectory: _downloadDir!,
    );
  }
}

/// Helper to build [PluginAppConfig] from runtime info.
///
/// Use this at app startup to create the app config for plugins.
class PluginAppConfigBuilder {
  /// Builds app config from the current environment.
  static PluginAppConfig fromPlatform({
    required String appVersion,
    required bool isDarkMode,
  }) {
    return PluginAppConfig(
      appVersion: appVersion,
      platform: _getPlatformName(),
      locale: Platform.localeName,
      isDarkMode: isDarkMode,
    );
  }

  static String _getPlatformName() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }
}
