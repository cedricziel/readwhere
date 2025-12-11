import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/di/service_locator.dart';
import '../providers/catalogs_provider.dart';
import '../screens/library/library_screen.dart';
import '../screens/catalogs/catalogs_screen.dart';
import '../screens/catalogs/browse/catalog_browse_screen.dart';
import '../screens/catalogs/browse/nextcloud_browser_screen.dart';
import '../screens/catalogs/browse/rss_browse_screen.dart';
import '../screens/catalogs/browse/unified_browse_screen.dart';
import '../screens/feeds/feeds_screen.dart';
import '../screens/feeds/article_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/reader/reader_screen.dart';
import '../widgets/adaptive/adaptive_scaffold.dart';
import 'routes.dart';
import '../../core/utils/logger.dart';

/// Navigation observer for tracking route changes and analytics.
///
/// This observer logs navigation events and can be extended to send
/// analytics data to services like Firebase Analytics, Mixpanel, etc.
class AppNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logNavigation('push', route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _logNavigation('pop', route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _logNavigation('replace', newRoute, oldRoute);
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _logNavigation('remove', route, previousRoute);
  }

  void _logNavigation(
    String action,
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    final routeName = route.settings.name ?? 'unknown';
    final previousRouteName = previousRoute?.settings.name ?? 'none';

    AppLogger.info('Navigation $action: $previousRouteName -> $routeName');

    // TODO: Send analytics event
    // Example: Firebase Analytics
    // FirebaseAnalytics.instance.logScreenView(
    //   screenName: routeName,
    //   screenClass: route.runtimeType.toString(),
    // );

    // Example: Custom analytics service
    // analyticsService.trackScreenView(
    //   screenName: routeName,
    //   previousScreen: previousRouteName,
    //   action: action,
    // );
  }
}

/// Creates and configures the GoRouter for the application.
///
/// The router uses a ShellRoute for main navigation (library, catalogs, feeds, settings)
/// with an adaptive scaffold, while the reader is a separate full-screen route.
///
/// Navigation events are tracked via [AppNavigationObserver] for analytics purposes.
GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: AppRoutes.library,
    debugLogDiagnostics: true,
    observers: [AppNavigationObserver()],
    routes: [
      // Root redirect
      GoRoute(
        path: AppRoutes.root,
        redirect: (context, state) => AppRoutes.library,
      ),

      // Shell route for main navigation with adaptive scaffold
      ShellRoute(
        builder: (context, state, child) {
          // Determine selected index based on current location
          final location = state.uri.path;
          final selectedIndex = AppDestinations.getIndexByRoute(location);

          return AdaptiveScaffold(
            selectedIndex: selectedIndex,
            destinations: AppDestinations.all,
            onDestinationSelected: (index) {
              final destination = AppDestinations.getByIndex(index);
              context.go(destination.route);
            },
            child: child,
          );
        },
        routes: [
          // Library route
          GoRoute(
            path: AppRoutes.library,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: LibraryScreen()),
          ),

          // Catalogs route
          GoRoute(
            path: AppRoutes.catalogs,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CatalogsScreen()),
          ),

          // Feeds route
          GoRoute(
            path: AppRoutes.feeds,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: FeedsScreen()),
          ),

          // Settings route
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),

      // Reader route (full screen, outside shell)
      GoRoute(
        path: AppRoutes.reader,
        builder: (context, state) {
          final bookId = state.pathParameters['bookId'];
          if (bookId == null || bookId.isEmpty) {
            // Redirect to library if no bookId provided
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go(AppRoutes.library);
            });
            return const SizedBox.shrink();
          }

          return ReaderScreen(bookId: bookId);
        },
      ),

      // Catalog browse route (full screen, outside shell)
      GoRoute(
        path: AppRoutes.catalogBrowse,
        builder: (context, state) {
          final catalogId = state.pathParameters['catalogId'];
          if (catalogId == null || catalogId.isEmpty) {
            // Redirect to catalogs if no catalogId provided
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go(AppRoutes.catalogs);
            });
            return const SizedBox.shrink();
          }

          return CatalogBrowseScreen(catalogId: catalogId);
        },
      ),

      // Nextcloud browse route (full screen, outside shell)
      GoRoute(
        path: AppRoutes.nextcloudBrowse,
        builder: (context, state) {
          final catalogId = state.pathParameters['catalogId'];
          if (catalogId == null || catalogId.isEmpty) {
            // Redirect to catalogs if no catalogId provided
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go(AppRoutes.catalogs);
            });
            return const SizedBox.shrink();
          }

          return NextcloudBrowserScreen(catalogId: catalogId);
        },
      ),

      // RSS browse route (full screen, outside shell)
      GoRoute(
        path: AppRoutes.rssBrowse,
        builder: (context, state) {
          final catalogId = state.pathParameters['catalogId'];
          if (catalogId == null || catalogId.isEmpty) {
            // Redirect to catalogs if no catalogId provided
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go(AppRoutes.catalogs);
            });
            return const SizedBox.shrink();
          }

          return RssBrowseScreen(catalogId: catalogId);
        },
      ),

      // Fanfiction browse route (full screen, outside shell)
      // Uses UnifiedBrowseScreen which works with the plugin system
      GoRoute(
        path: AppRoutes.fanfictionBrowse,
        builder: (context, state) {
          final catalogId = state.pathParameters['catalogId'];
          if (catalogId == null || catalogId.isEmpty) {
            // Redirect to catalogs if no catalogId provided
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go(AppRoutes.catalogs);
            });
            return const SizedBox.shrink();
          }

          // Load catalog and return UnifiedBrowseScreen
          return FutureBuilder(
            future: sl<CatalogsProvider>().getCatalogById(catalogId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final catalog = snapshot.data;
              if (catalog == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.go(AppRoutes.catalogs);
                });
                return const SizedBox.shrink();
              }

              return UnifiedBrowseScreen(catalog: catalog);
            },
          );
        },
      ),

      // Article route (full screen, for reading feed items)
      GoRoute(
        path: AppRoutes.article,
        builder: (context, state) {
          final feedId = state.pathParameters['feedId'];
          final rawItemId = state.pathParameters['itemId'];
          if (feedId == null ||
              feedId.isEmpty ||
              rawItemId == null ||
              rawItemId.isEmpty) {
            // Redirect to feeds if parameters missing
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go(AppRoutes.feeds);
            });
            return const SizedBox.shrink();
          }

          // Decode the itemId (RSS item IDs are often URLs that were encoded)
          final itemId = Uri.decodeComponent(rawItemId);

          return ArticleScreen(feedId: feedId, itemId: itemId);
        },
      ),
    ],

    // Error handling
    errorBuilder: (context, state) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Page Not Found',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                state.uri.toString(),
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.library),
                child: const Text('Go to Library'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
