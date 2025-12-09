import 'package:flutter/foundation.dart';

/// Abstract interface for catalog browsing state providers.
///
/// This provides a common interface that all catalog-type specific providers
/// (OPDS, Kavita, Nextcloud, etc.) implement for UI consumption.
///
/// **Note**: For new catalog implementations, consider using
/// [UnifiedCatalogBrowsingProvider] which wraps [CatalogBrowsingCapability]
/// plugins and provides automatic plugin discovery.
///
/// Extends [ChangeNotifier] for Flutter state management integration.
abstract class BrowsingProvider extends ChangeNotifier {
  /// Whether an operation is in progress
  bool get isLoading;

  /// Current error message, if any
  String? get error;

  /// Clear the current error
  void clearError();

  /// Whether navigation back is possible
  bool get canNavigateBack;

  /// Breadcrumb trail for current location
  List<String> get breadcrumbs;

  /// Navigate back to previous location
  ///
  /// Returns true if navigation occurred, false if already at root
  Future<bool> navigateBack();

  /// Refresh the current view
  Future<void> refresh();

  /// Close the browser and reset state
  void closeBrowser();

  /// Get download progress for an item (0.0 to 1.0)
  ///
  /// Returns null if not currently downloading
  double? getDownloadProgress(String itemId);

  /// Whether an item is currently being downloaded
  bool isDownloading(String itemId) => getDownloadProgress(itemId) != null;

  /// Whether an item has been downloaded
  bool isDownloaded(String itemId);
}
