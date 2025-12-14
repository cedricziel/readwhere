import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../router/routes.dart';

/// macOS-native scaffold with sidebar navigation.
///
/// Uses the macos_ui package to provide a native macOS experience
/// with a collapsible sidebar and proper macOS styling.
///
/// This scaffold should only be used on macOS. For other platforms,
/// use [AdaptiveTabScaffold] or [AdaptiveScaffold].
///
/// Example:
/// ```dart
/// MacosAdaptiveScaffold(
///   selectedIndex: currentIndex,
///   onDestinationSelected: (index) => setState(() => currentIndex = index),
///   destinations: AppDestinations.all,
///   child: screens[selectedIndex],
/// )
/// ```
class MacosAdaptiveScaffold extends StatelessWidget {
  /// The currently selected destination index.
  final int selectedIndex;

  /// Callback when a navigation destination is selected.
  final ValueChanged<int> onDestinationSelected;

  /// Navigation destinations.
  final List<AppNavigationDestination> destinations;

  /// The main content to display.
  final Widget child;

  /// Optional toolbar for the content area.
  final ToolBar? toolBar;

  /// Minimum width of the sidebar.
  final double minSidebarWidth;

  /// Maximum width of the sidebar.
  final double maxSidebarWidth;

  /// Starting width of the sidebar.
  final double startSidebarWidth;

  const MacosAdaptiveScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.child,
    this.toolBar,
    this.minSidebarWidth = 200,
    this.maxSidebarWidth = 300,
    this.startSidebarWidth = 220,
  });

  @override
  Widget build(BuildContext context) {
    return MacosWindow(
      sidebar: Sidebar(
        minWidth: minSidebarWidth,
        maxWidth: maxSidebarWidth,
        startWidth: startSidebarWidth,
        builder: (context, scrollController) {
          return SidebarItems(
            currentIndex: selectedIndex,
            scrollController: scrollController,
            itemSize: SidebarItemSize.large,
            onChanged: onDestinationSelected,
            items: destinations.map((dest) {
              return SidebarItem(
                leading: MacosIcon(dest.cupertinoIcon),
                label: Text(dest.label),
              );
            }).toList(),
          );
        },
        // Bottom items (optional - could add settings here)
        bottom: const MacosListTile(
          leading: MacosIcon(CupertinoIcons.info_circle),
          title: Text('ReadWhere'),
          subtitle: Text('E-Reader'),
        ),
      ),
      child: MacosScaffold(
        toolBar: toolBar,
        children: [
          ContentArea(
            builder: (context, scrollController) {
              return child;
            },
          ),
        ],
      ),
    );
  }
}

/// A builder widget that constructs the appropriate scaffold based on platform.
///
/// This is a convenience widget that automatically chooses between
/// [MacosAdaptiveScaffold] on macOS and [AdaptiveTabScaffold] elsewhere.
///
/// Example:
/// ```dart
/// PlatformAdaptiveScaffold(
///   selectedIndex: currentIndex,
///   onDestinationSelected: (index) => setState(() => currentIndex = index),
///   destinations: AppDestinations.all,
///   tabBuilder: (context, index) => screens[index],
/// )
/// ```
class PlatformAdaptiveScaffold extends StatelessWidget {
  /// The currently selected destination index.
  final int selectedIndex;

  /// Callback when a navigation destination is selected.
  final ValueChanged<int> onDestinationSelected;

  /// Navigation destinations.
  final List<AppNavigationDestination> destinations;

  /// Builder for tab/screen content.
  final IndexedWidgetBuilder tabBuilder;

  /// Optional toolbar for macOS.
  final ToolBar? macosToolBar;

  const PlatformAdaptiveScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.tabBuilder,
    this.macosToolBar,
  });

  @override
  Widget build(BuildContext context) {
    // Note: Platform detection should be done at the app level
    // This widget is for use within MaterialApp, not MacosApp
    // MacosApp should use MacosAdaptiveScaffold directly

    // For non-macOS platforms, we import from adaptive_tab_scaffold
    // But since this file is macos_scaffold.dart, we just build the macOS version
    return MacosAdaptiveScaffold(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: destinations,
      toolBar: macosToolBar,
      child: tabBuilder(context, selectedIndex),
    );
  }
}
