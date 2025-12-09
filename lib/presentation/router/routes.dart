import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Navigation destination information.
class AppNavigationDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;

  const AppNavigationDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });
}

/// Route path constants for the application.
///
/// This class centralizes all route paths to avoid hardcoded strings
/// throughout the codebase and provides type-safe navigation helpers.
class AppRoutes {
  // Private constructor to prevent instantiation
  AppRoutes._();

  // Root routes
  static const String root = '/';
  static const String library = '/library';
  static const String catalogs = '/catalogs';
  static const String feeds = '/feeds';
  static const String settings = '/settings';

  // Reader routes (full screen, outside shell)
  static const String reader = '/reader/:bookId';

  // Catalog browse route (full screen, outside shell)
  static const String catalogBrowse = '/catalogs/:catalogId/browse';

  // Nextcloud browse route (full screen, outside shell)
  static const String nextcloudBrowse = '/catalogs/:catalogId/nextcloud';

  // RSS browse route (full screen, outside shell)
  static const String rssBrowse = '/catalogs/:catalogId/rss';

  /// Generates the catalog browse path with the given catalog ID.
  ///
  /// [catalogId] is the unique identifier of the catalog.
  static String catalogBrowsePath(String catalogId) {
    return '/catalogs/$catalogId/browse';
  }

  /// Generates the Nextcloud browse path with the given catalog ID.
  ///
  /// [catalogId] is the unique identifier of the Nextcloud catalog.
  static String nextcloudBrowsePath(String catalogId) {
    return '/catalogs/$catalogId/nextcloud';
  }

  /// Generates the RSS browse path with the given catalog ID.
  ///
  /// [catalogId] is the unique identifier of the RSS catalog.
  static String rssBrowsePath(String catalogId) {
    return '/catalogs/$catalogId/rss';
  }

  // Navigation helper methods

  /// Navigates to the library screen.
  static void goToLibrary(GoRouter router) {
    router.go(library);
  }

  /// Navigates to the catalogs screen.
  static void goToCatalogs(GoRouter router) {
    router.go(catalogs);
  }

  /// Navigates to the feeds screen.
  static void goToFeeds(GoRouter router) {
    router.go(feeds);
  }

  /// Navigates to the settings screen.
  static void goToSettings(GoRouter router) {
    router.go(settings);
  }

  /// Navigates to the reader screen for a specific book.
  ///
  /// [bookId] is the unique identifier of the book to read.
  static void goToReader(GoRouter router, String bookId) {
    router.go(readerPath(bookId));
  }

  /// Pushes the reader screen onto the navigation stack.
  ///
  /// [bookId] is the unique identifier of the book to read.
  /// This method maintains the current navigation history.
  static Future<void> pushReader(GoRouter router, String bookId) {
    return router.push(readerPath(bookId));
  }

  /// Generates the reader path with the given book ID.
  ///
  /// [bookId] is the unique identifier of the book.
  static String readerPath(String bookId) {
    return '/reader/$bookId';
  }

  /// Navigates back in the navigation stack.
  static void goBack(GoRouter router) {
    router.pop();
  }
}

/// Predefined navigation destinations for the app.
class AppDestinations {
  AppDestinations._();

  static const library = AppNavigationDestination(
    label: 'Library',
    icon: Icons.library_books_outlined,
    selectedIcon: Icons.library_books,
    route: AppRoutes.library,
  );

  static const catalogs = AppNavigationDestination(
    label: 'Catalogs',
    icon: Icons.public_outlined,
    selectedIcon: Icons.public,
    route: AppRoutes.catalogs,
  );

  static const feeds = AppNavigationDestination(
    label: 'Feeds',
    icon: Icons.rss_feed_outlined,
    selectedIcon: Icons.rss_feed,
    route: AppRoutes.feeds,
  );

  static const settings = AppNavigationDestination(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    route: AppRoutes.settings,
  );

  /// All main navigation destinations in order.
  static const List<AppNavigationDestination> all = [
    library,
    catalogs,
    feeds,
    settings,
  ];

  /// Gets the index of a destination by route path.
  static int getIndexByRoute(String route) {
    final index = all.indexWhere((dest) => dest.route == route);
    return index >= 0 ? index : 0;
  }

  /// Gets a destination by index.
  static AppNavigationDestination getByIndex(int index) {
    if (index >= 0 && index < all.length) {
      return all[index];
    }
    return library;
  }
}
