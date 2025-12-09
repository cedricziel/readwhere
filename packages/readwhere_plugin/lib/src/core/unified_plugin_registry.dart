import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../storage/plugin_storage.dart';
import 'plugin_base.dart';
import 'plugin_context.dart';

/// Unified registry for all plugins.
///
/// Singleton that manages plugin lifecycle, registration, and lookup.
/// Provides capability-based querying for finding plugins that can
/// handle specific operations.
///
/// Example usage:
/// ```dart
/// final registry = UnifiedPluginRegistry();
///
/// // Register plugins
/// await registry.register(
///   KavitaPlugin(),
///   storageFactory: myStorageFactory,
///   contextFactory: myContextFactory,
/// );
///
/// // Find plugins by capability
/// final catalogs = registry.withCapability<CatalogCapability>();
///
/// // Find plugin for a file
/// final reader = await registry.forFile('/path/to/book.epub');
/// ```
class UnifiedPluginRegistry {
  static final UnifiedPluginRegistry _instance =
      UnifiedPluginRegistry._internal();

  /// Returns the singleton instance.
  factory UnifiedPluginRegistry() => _instance;

  UnifiedPluginRegistry._internal();

  final Map<String, PluginBase> _plugins = {};
  final Map<String, List<ChangeNotifier>> _providers = {};
  final Map<String, PluginContext> _contexts = {};

  // ===== Registration =====

  /// Register a plugin with the registry.
  ///
  /// Creates a context, initializes the plugin, and creates its providers.
  ///
  /// [plugin] The plugin to register.
  /// [storageFactory] Factory for creating plugin storage.
  /// [contextFactory] Factory for creating plugin context.
  ///
  /// Throws [PluginAlreadyRegisteredException] if a plugin with the
  /// same ID is already registered.
  /// Throws if plugin initialization fails.
  Future<void> register(
    PluginBase plugin, {
    required PluginStorageFactory storageFactory,
    required PluginContextFactory contextFactory,
  }) async {
    if (_plugins.containsKey(plugin.id)) {
      throw PluginAlreadyRegisteredException(plugin.id);
    }

    final storage = await storageFactory.create(plugin.id);
    final context = await contextFactory.create(plugin.id, storage);

    await plugin.initialize(context);

    _plugins[plugin.id] = plugin;
    _contexts[plugin.id] = context;
    _providers[plugin.id] = plugin.createProviders(context);
  }

  /// Register a plugin with pre-created context.
  ///
  /// Use this when you've already created the storage and context
  /// outside the registry.
  Future<void> registerWithContext(
    PluginBase plugin,
    PluginContext context,
  ) async {
    if (_plugins.containsKey(plugin.id)) {
      throw PluginAlreadyRegisteredException(plugin.id);
    }

    await plugin.initialize(context);

    _plugins[plugin.id] = plugin;
    _contexts[plugin.id] = context;
    _providers[plugin.id] = plugin.createProviders(context);
  }

  /// Unregister a plugin.
  ///
  /// Disposes the plugin and its providers, removes from registry.
  /// Returns true if the plugin was found and removed.
  Future<bool> unregister(String pluginId) async {
    final plugin = _plugins.remove(pluginId);
    if (plugin == null) return false;

    await plugin.dispose();

    // Dispose providers
    final providers = _providers.remove(pluginId);
    if (providers != null) {
      for (final provider in providers) {
        provider.dispose();
      }
    }

    _contexts.remove(pluginId);
    return true;
  }

  /// Unregister all plugins.
  Future<void> clear() async {
    final pluginIds = _plugins.keys.toList();
    for (final id in pluginIds) {
      await unregister(id);
    }
  }

  // ===== Lookup by ID =====

  /// Get a plugin by ID.
  ///
  /// Returns null if not found.
  PluginBase? get(String id) => _plugins[id];

  /// Get a plugin by ID, throwing if not found.
  PluginBase getOrThrow(String id) {
    final plugin = _plugins[id];
    if (plugin == null) {
      throw PluginNotFoundException(id);
    }
    return plugin;
  }

  /// Get a plugin by ID, cast to a specific type.
  ///
  /// Returns null if not found or if the plugin is not of the
  /// requested type.
  T? getAs<T extends PluginBase>(String id) {
    final plugin = _plugins[id];
    return plugin is T ? plugin : null;
  }

  /// Get all registered plugins.
  Iterable<PluginBase> get all => _plugins.values;

  /// Get all plugin IDs.
  Iterable<String> get ids => _plugins.keys;

  /// Number of registered plugins.
  int get count => _plugins.length;

  /// Whether any plugins are registered.
  bool get isEmpty => _plugins.isEmpty;

  /// Whether plugins are registered.
  bool get isNotEmpty => _plugins.isNotEmpty;

  /// Check if a plugin is registered.
  bool isRegistered(String id) => _plugins.containsKey(id);

  // ===== Lookup by Capability =====

  /// Get all plugins with a specific capability.
  ///
  /// Example:
  /// ```dart
  /// final catalogs = registry.withCapability<CatalogCapability>();
  /// for (final catalog in catalogs) {
  ///   await catalog.browse(info);
  /// }
  /// ```
  Iterable<T> withCapability<T>() {
    return _plugins.values.whereType<T>();
  }

  /// Get the first plugin with a specific capability.
  ///
  /// Returns null if no plugin has the capability.
  T? firstWithCapability<T>() {
    for (final plugin in _plugins.values) {
      if (plugin is T) return plugin as T;
    }
    return null;
  }

  /// Check if any plugin has a specific capability.
  bool hasCapability<T>() {
    return _plugins.values.any((p) => p is T);
  }

  /// Count plugins with a specific capability.
  int countWithCapability<T>() {
    return _plugins.values.whereType<T>().length;
  }

  // ===== Lookup for Files (ReaderCapability) =====

  /// Find a plugin that can handle the given file.
  ///
  /// Checks file extension first, then calls canHandleFile() for
  /// validation (e.g., magic byte checking).
  ///
  /// Returns null if no plugin can handle the file.
  ///
  /// Note: This method requires plugins to implement an interface
  /// with `supportedExtensions` and `canHandleFile` (e.g., ReaderCapability).
  /// The actual type checking is done dynamically.
  Future<T?> forFile<T>(String filePath) async {
    final extension = path
        .extension(filePath)
        .toLowerCase()
        .replaceFirst('.', '');

    // Get all plugins with the capability
    final candidates = <T>[];
    for (final plugin in _plugins.values) {
      if (plugin is T) {
        // Check if plugin declares support for this extension
        final dynamic p = plugin;
        if (p.supportedExtensions?.contains(extension) == true) {
          candidates.add(plugin as T);
        }
      }
    }

    // Validate with canHandleFile
    for (final plugin in candidates) {
      final dynamic p = plugin;
      if (await p.canHandleFile(filePath) == true) {
        return plugin;
      }
    }

    return null;
  }

  /// Find a plugin that supports the given MIME type.
  ///
  /// Note: This method requires plugins to implement an interface
  /// with `supportedMimeTypes` (e.g., ReaderCapability).
  T? forMimeType<T>(String mimeType) {
    for (final plugin in _plugins.values) {
      if (plugin is T) {
        final dynamic p = plugin;
        if (p.supportedMimeTypes?.contains(mimeType) == true) {
          return plugin as T;
        }
      }
    }
    return null;
  }

  /// Get all supported file extensions across all plugins with the capability.
  Set<String> supportedExtensions<T>() {
    final extensions = <String>{};
    for (final plugin in _plugins.values) {
      if (plugin is T) {
        final dynamic p = plugin;
        final exts = p.supportedExtensions;
        if (exts != null) {
          extensions.addAll(List<String>.from(exts));
        }
      }
    }
    return extensions;
  }

  /// Get all supported MIME types across all plugins with the capability.
  Set<String> supportedMimeTypes<T>() {
    final mimeTypes = <String>{};
    for (final plugin in _plugins.values) {
      if (plugin is T) {
        final dynamic p = plugin;
        final types = p.supportedMimeTypes;
        if (types != null) {
          mimeTypes.addAll(List<String>.from(types));
        }
      }
    }
    return mimeTypes;
  }

  // ===== Lookup for Catalogs (CatalogCapability) =====

  /// Find a plugin that can handle the given catalog.
  ///
  /// Note: This method requires plugins to implement an interface
  /// with `canHandleCatalog` (e.g., CatalogCapability).
  T? forCatalog<T>(dynamic catalogInfo) {
    for (final plugin in _plugins.values) {
      if (plugin is T) {
        final dynamic p = plugin;
        if (p.canHandleCatalog(catalogInfo) == true) {
          return plugin as T;
        }
      }
    }
    return null;
  }

  // ===== Provider Access =====

  /// Get a provider by type from a specific plugin.
  ///
  /// Returns null if the plugin doesn't exist or doesn't have
  /// a provider of the requested type.
  T? getProvider<T extends ChangeNotifier>(String pluginId) {
    final providers = _providers[pluginId];
    if (providers == null) return null;

    for (final provider in providers) {
      if (provider is T) return provider;
    }
    return null;
  }

  /// Get all providers of a specific type across all plugins.
  Iterable<T> getProvidersOfType<T extends ChangeNotifier>() sync* {
    for (final providers in _providers.values) {
      for (final provider in providers) {
        if (provider is T) yield provider;
      }
    }
  }

  /// Get all providers for a plugin.
  List<ChangeNotifier> getProvidersFor(String pluginId) {
    return _providers[pluginId] ?? [];
  }

  /// Get the context for a plugin.
  ///
  /// Returns null if the plugin is not registered.
  PluginContext? getContext(String pluginId) => _contexts[pluginId];

  // ===== Debugging =====

  /// Get a debug summary of registered plugins.
  String debugSummary() {
    final buffer = StringBuffer();
    buffer.writeln('UnifiedPluginRegistry:');
    buffer.writeln('  Plugins: ${_plugins.length}');
    for (final plugin in _plugins.values) {
      final providerCount = _providers[plugin.id]?.length ?? 0;
      buffer.writeln('    - ${plugin.id}');
      buffer.writeln('      Name: ${plugin.name}');
      buffer.writeln('      Version: ${plugin.version}');
      buffer.writeln(
        '      Capabilities: ${plugin.capabilityNames.join(', ')}',
      );
      buffer.writeln('      Providers: $providerCount');
    }
    return buffer.toString();
  }
}

/// Exception thrown when registering a plugin with a duplicate ID.
class PluginAlreadyRegisteredException implements Exception {
  /// The duplicate plugin ID.
  final String pluginId;

  /// Creates the exception.
  PluginAlreadyRegisteredException(this.pluginId);

  @override
  String toString() =>
      'PluginAlreadyRegisteredException: '
      'Plugin already registered with ID: $pluginId';
}

/// Exception thrown when a plugin is not found.
class PluginNotFoundException implements Exception {
  /// The plugin ID that was not found.
  final String pluginId;

  /// Creates the exception.
  PluginNotFoundException(this.pluginId);

  @override
  String toString() =>
      'PluginNotFoundException: '
      'No plugin found with ID: $pluginId';
}
