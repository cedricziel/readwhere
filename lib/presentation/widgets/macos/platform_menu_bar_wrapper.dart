import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../router/routes.dart';

/// Wraps the app with a native macOS menu bar.
///
/// This widget uses Flutter's [PlatformMenuBar] to provide native
/// macOS menu integration with keyboard shortcuts.
///
/// Only active on macOS. On other platforms, it simply returns the child.
///
/// Example:
/// ```dart
/// PlatformMenuBarWrapper(
///   router: appRouter,
///   child: MacosApp(...),
/// )
/// ```
class PlatformMenuBarWrapper extends StatelessWidget {
  /// The GoRouter instance for navigation.
  final GoRouter router;

  /// The child widget to wrap.
  final Widget child;

  /// Callback when "Open Book" is selected from the menu.
  final VoidCallback? onOpenBook;

  /// Callback when "Search" is selected from the menu.
  final VoidCallback? onSearch;

  const PlatformMenuBarWrapper({
    super.key,
    required this.router,
    required this.child,
    this.onOpenBook,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    // Only show menu bar on macOS
    if (kIsWeb || !Platform.isMacOS) {
      return child;
    }

    return PlatformMenuBar(menus: _buildMenus(context), child: child);
  }

  List<PlatformMenu> _buildMenus(BuildContext context) {
    return [
      // App Menu (ReadWhere)
      PlatformMenu(
        label: 'ReadWhere',
        menus: [
          PlatformMenuItemGroup(
            members: [
              PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.about,
              ),
            ],
          ),
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: 'Preferences...',
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.comma,
                  meta: true,
                ),
                onSelected: () => router.go(AppRoutes.settings),
              ),
            ],
          ),
          PlatformMenuItemGroup(
            members: [
              PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.servicesSubmenu,
              ),
            ],
          ),
          PlatformMenuItemGroup(
            members: [
              PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.hide),
              PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.hideOtherApplications,
              ),
              PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.showAllApplications,
              ),
            ],
          ),
          PlatformMenuItemGroup(
            members: [
              PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.quit),
            ],
          ),
        ],
      ),

      // File Menu
      PlatformMenu(
        label: 'File',
        menus: [
          PlatformMenuItem(
            label: 'Open Book...',
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyO,
              meta: true,
            ),
            onSelected: onOpenBook,
          ),
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: 'Close Window',
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyW,
                  meta: true,
                ),
                onSelected: () {
                  // Close the current window/view
                  // This could navigate back or close a dialog
                },
              ),
            ],
          ),
        ],
      ),

      // Library Menu
      PlatformMenu(
        label: 'Library',
        menus: [
          PlatformMenuItem(
            label: 'Go to Library',
            shortcut: const SingleActivator(
              LogicalKeyboardKey.digit1,
              meta: true,
            ),
            onSelected: () => router.go(AppRoutes.library),
          ),
          PlatformMenuItem(
            label: 'Go to Catalogs',
            shortcut: const SingleActivator(
              LogicalKeyboardKey.digit2,
              meta: true,
            ),
            onSelected: () => router.go(AppRoutes.catalogs),
          ),
          PlatformMenuItem(
            label: 'Go to Feeds',
            shortcut: const SingleActivator(
              LogicalKeyboardKey.digit3,
              meta: true,
            ),
            onSelected: () => router.go(AppRoutes.feeds),
          ),
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: 'Search Library',
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyF,
                  meta: true,
                ),
                onSelected: onSearch,
              ),
            ],
          ),
        ],
      ),

      // Reader Menu
      PlatformMenu(
        label: 'Reader',
        menus: [
          PlatformMenuItem(
            label: 'Previous Chapter',
            shortcut: const SingleActivator(
              LogicalKeyboardKey.arrowLeft,
              meta: true,
            ),
            onSelected: () {
              // This would need to be connected to reader state
            },
          ),
          PlatformMenuItem(
            label: 'Next Chapter',
            shortcut: const SingleActivator(
              LogicalKeyboardKey.arrowRight,
              meta: true,
            ),
            onSelected: () {
              // This would need to be connected to reader state
            },
          ),
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: 'Table of Contents',
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyT,
                  meta: true,
                ),
                onSelected: () {
                  // This would need to be connected to reader state
                },
              ),
              PlatformMenuItem(
                label: 'Add Bookmark',
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyD,
                  meta: true,
                ),
                onSelected: () {
                  // This would need to be connected to reader state
                },
              ),
            ],
          ),
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: 'Increase Font Size',
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.equal,
                  meta: true,
                ),
                onSelected: () {
                  // This would need to be connected to reader settings
                },
              ),
              PlatformMenuItem(
                label: 'Decrease Font Size',
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.minus,
                  meta: true,
                ),
                onSelected: () {
                  // This would need to be connected to reader settings
                },
              ),
            ],
          ),
        ],
      ),

      // Window Menu
      PlatformMenu(
        label: 'Window',
        menus: [
          PlatformProvidedMenuItem(
            type: PlatformProvidedMenuItemType.minimizeWindow,
          ),
          PlatformProvidedMenuItem(
            type: PlatformProvidedMenuItemType.zoomWindow,
          ),
          PlatformMenuItemGroup(
            members: [
              PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.toggleFullScreen,
              ),
            ],
          ),
          PlatformMenuItemGroup(
            members: [
              PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.arrangeWindowsInFront,
              ),
            ],
          ),
        ],
      ),

      // Help Menu
      PlatformMenu(
        label: 'Help',
        menus: [
          PlatformMenuItem(
            label: 'ReadWhere Help',
            onSelected: () {
              // Open help documentation
            },
          ),
          PlatformMenuItem(
            label: 'Report an Issue',
            onSelected: () {
              // Open GitHub issues page
            },
          ),
        ],
      ),
    ];
  }
}
