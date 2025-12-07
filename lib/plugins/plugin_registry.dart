import 'reader_plugin.dart';

/// Singleton registry for managing reader plugins
///
/// This class maintains a collection of plugins and provides methods
/// to register new plugins and find appropriate plugins for files.
class PluginRegistry {
  static final PluginRegistry _instance = PluginRegistry._internal();

  factory PluginRegistry() {
    return _instance;
  }

  PluginRegistry._internal();

  final List<ReaderPlugin> _plugins = [];

  /// Register a new plugin
  ///
  /// If a plugin with the same ID already exists, it will be replaced.
  void register(ReaderPlugin plugin) {
    // Remove existing plugin with same ID if present
    _plugins.removeWhere((p) => p.id == plugin.id);
    _plugins.add(plugin);
  }

  /// Find a plugin that can handle the given file
  ///
  /// Returns the first plugin that reports it can handle the file,
  /// or null if no suitable plugin is found.
  Future<ReaderPlugin?> getPluginForFile(String filePath) async {
    for (final plugin in _plugins) {
      if (await plugin.canHandle(filePath)) {
        return plugin;
      }
    }
    return null;
  }

  /// Find a plugin by its ID
  ///
  /// Returns null if no plugin with the given ID is registered.
  ReaderPlugin? getPluginById(String id) {
    try {
      return _plugins.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get all registered plugins
  List<ReaderPlugin> getAllPlugins() {
    return List.unmodifiable(_plugins);
  }

  /// Get all supported file extensions across all plugins
  ///
  /// Returns a deduplicated list of extensions (without the dot prefix).
  List<String> getSupportedExtensions() {
    final extensions = <String>{};
    for (final plugin in _plugins) {
      extensions.addAll(plugin.supportedExtensions);
    }
    return extensions.toList()..sort();
  }

  /// Get all supported MIME types across all plugins
  ///
  /// Returns a deduplicated list of MIME types.
  List<String> getSupportedMimeTypes() {
    final mimeTypes = <String>{};
    for (final plugin in _plugins) {
      mimeTypes.addAll(plugin.supportedMimeTypes);
    }
    return mimeTypes.toList()..sort();
  }

  /// Unregister a plugin by ID
  ///
  /// Returns true if the plugin was found and removed, false otherwise.
  bool unregister(String id) {
    final initialLength = _plugins.length;
    _plugins.removeWhere((p) => p.id == id);
    return _plugins.length < initialLength;
  }

  /// Clear all registered plugins
  void clear() {
    _plugins.clear();
  }

  /// Get the number of registered plugins
  int get pluginCount => _plugins.length;

  /// Check if a file extension is supported by any plugin
  bool isExtensionSupported(String extension) {
    final normalizedExt = extension.toLowerCase().replaceAll('.', '');
    return _plugins.any(
      (plugin) => plugin.supportedExtensions.any(
        (ext) => ext.toLowerCase() == normalizedExt,
      ),
    );
  }

  /// Check if a MIME type is supported by any plugin
  bool isMimeTypeSupported(String mimeType) {
    return _plugins.any(
      (plugin) => plugin.supportedMimeTypes.contains(mimeType),
    );
  }

  /// Get plugins that support a specific file extension
  List<ReaderPlugin> getPluginsByExtension(String extension) {
    final normalizedExt = extension.toLowerCase().replaceAll('.', '');
    return _plugins
        .where(
          (plugin) => plugin.supportedExtensions.any(
            (ext) => ext.toLowerCase() == normalizedExt,
          ),
        )
        .toList();
  }

  /// Get plugins that support a specific MIME type
  List<ReaderPlugin> getPluginsByMimeType(String mimeType) {
    return _plugins
        .where((plugin) => plugin.supportedMimeTypes.contains(mimeType))
        .toList();
  }
}
