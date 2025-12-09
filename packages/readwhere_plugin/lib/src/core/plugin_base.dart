import 'package:flutter/foundation.dart';

import 'plugin_context.dart';

/// Base class for all plugins in ReadWhere.
///
/// Plugins extend this class and mix in capability interfaces to define
/// their functionality. A single plugin can provide multiple capabilities:
/// - [CatalogCapability] for browsing/downloading from catalogs
/// - [ReaderCapability] for reading book files
/// - [AccountCapability] for authentication
/// - [ProgressSyncCapability] for syncing reading progress
/// - [SettingsCapability] for plugin configuration
///
/// Example:
/// ```dart
/// class KavitaPlugin extends PluginBase
///     with CatalogCapability, AccountCapability, ProgressSyncCapability {
///   @override
///   String get id => 'com.readwhere.kavita';
///
///   @override
///   String get name => 'Kavita';
///
///   // ... implement capability methods
/// }
/// ```
abstract class PluginBase {
  /// Unique reverse-domain identifier for this plugin.
  ///
  /// Example: 'com.readwhere.kavita', 'com.readwhere.epub'
  String get id;

  /// Human-readable name for display in the UI.
  String get name;

  /// Description of what this plugin does.
  String get description;

  /// Plugin version using semantic versioning.
  ///
  /// Example: '1.0.0', '2.1.3'
  String get version;

  /// Optional icon asset path or URL for the plugin.
  ///
  /// Can be a local asset path ('assets/icons/kavita.png') or
  /// a network URL for dynamic icons.
  String? get iconPath => null;

  /// List of capability names this plugin provides.
  ///
  /// Override this in your plugin to declare supported capabilities.
  /// This is used for debugging and UI display purposes.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// List<String> get capabilityNames => [
  ///   'CatalogCapability',
  ///   'AccountCapability',
  /// ];
  /// ```
  ///
  /// For type-safe capability checking, use [hasCapability<T>()].
  List<String> get capabilityNames => [];

  /// Check if this plugin has a specific capability.
  ///
  /// Example:
  /// ```dart
  /// if (plugin.hasCapability<CatalogCapability>()) {
  ///   final catalog = plugin as CatalogCapability;
  ///   await catalog.browse(info);
  /// }
  /// ```
  bool hasCapability<T>() => this is T;

  /// Cast this plugin to a specific capability type.
  ///
  /// Returns null if the plugin doesn't have the capability.
  ///
  /// Example:
  /// ```dart
  /// final catalog = plugin.asCapability<CatalogCapability>();
  /// if (catalog != null) {
  ///   await catalog.browse(info);
  /// }
  /// ```
  T? asCapability<T>() => this is T ? this as T : null;

  /// Initialize the plugin with context.
  ///
  /// Called once when the plugin is registered with the registry.
  /// Plugins should use this to set up any required state, initialize
  /// clients, or validate configuration.
  ///
  /// The [context] provides access to storage, HTTP client, logging,
  /// and other services the plugin may need.
  ///
  /// Throws if initialization fails.
  Future<void> initialize(PluginContext context);

  /// Dispose of plugin resources.
  ///
  /// Called when the plugin is unregistered or the app is shutting down.
  /// Plugins should clean up any resources, close connections, and
  /// cancel any pending operations.
  Future<void> dispose();

  /// Create ChangeNotifier providers for UI binding.
  ///
  /// Returns a list of ChangeNotifier instances that the UI can use
  /// for state management. These providers are scoped to this plugin
  /// and registered with the plugin registry for UI access.
  ///
  /// Override this to provide plugin-specific state management:
  /// ```dart
  /// @override
  /// List<ChangeNotifier> createProviders(PluginContext context) {
  ///   return [
  ///     MyPluginBrowsingProvider(this, context),
  ///     MyPluginSettingsProvider(this, context),
  ///   ];
  /// }
  /// ```
  ///
  /// Returns an empty list by default.
  List<ChangeNotifier> createProviders(PluginContext context) => [];

  /// Called when plugin settings change.
  ///
  /// Override to react to configuration updates. This is called
  /// after settings have been persisted to storage.
  ///
  /// [settings] contains all current settings for this plugin.
  void onSettingsChanged(Map<String, dynamic> settings) {}

  @override
  String toString() => 'Plugin($id: $name v$version)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PluginBase && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
