import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../router/routes.dart';
import 'macos_scaffold.dart';

/// Adaptive tab scaffold that provides platform-native navigation.
///
/// This is an enhanced version of [AdaptiveScaffold] that provides
/// proper iOS-native navigation:
///
/// - **iPhone**: [CupertinoTabBar] at bottom with content
/// - **iPad**: Split-view with sidebar navigation
/// - **Android/Web Mobile**: Material [NavigationBar]
/// - **Android/Web Desktop**: Material [NavigationRail]
///
/// For macOS, use [MacosAdaptiveScaffold] which provides native sidebar
/// navigation via the macos_ui package.
///
/// Supports two usage patterns:
///
/// 1. **With go_router** (using [child]):
/// ```dart
/// AdaptiveTabScaffold(
///   selectedIndex: currentIndex,
///   onDestinationSelected: (index) => context.go(routes[index]),
///   destinations: AppDestinations.all,
///   child: child, // Provided by ShellRoute
/// )
/// ```
///
/// 2. **Standalone** (using [tabBuilder]):
/// ```dart
/// AdaptiveTabScaffold(
///   selectedIndex: currentIndex,
///   onDestinationSelected: (index) => setState(() => currentIndex = index),
///   destinations: AppDestinations.all,
///   tabBuilder: (context, index) => screens[index],
/// )
/// ```
class AdaptiveTabScaffold extends StatelessWidget {
  /// The currently selected destination index.
  final int selectedIndex;

  /// Callback when a navigation destination is selected.
  final ValueChanged<int> onDestinationSelected;

  /// Navigation destinations.
  final List<AppNavigationDestination> destinations;

  /// Builder for tab content.
  ///
  /// Use this when managing navigation state internally (not with go_router).
  /// Each tab maintains its own navigation stack via [CupertinoTabView] on iOS.
  final IndexedWidgetBuilder? tabBuilder;

  /// The main content to display.
  ///
  /// Use this when navigation is handled externally (e.g., with go_router).
  /// The child is displayed directly in the content area.
  final Widget? child;

  const AdaptiveTabScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.tabBuilder,
    this.child,
  }) : assert(
         tabBuilder != null || child != null,
         'Either tabBuilder or child must be provided',
       );

  @override
  Widget build(BuildContext context) {
    // macOS: Use native sidebar via macos_ui
    if (!kIsWeb && Platform.isMacOS) {
      return _buildMacosScaffold(context);
    }

    // iOS: Use CupertinoTabScaffold
    if (context.isIOS) {
      if (context.isIPad) {
        return _buildIPadSplitView(context);
      }
      return _buildCupertinoTabScaffold(context);
    }

    // Other platforms: Use Material navigation
    return _buildMaterialScaffold(context);
  }

  Widget _buildMacosScaffold(BuildContext context) {
    final content = child ?? tabBuilder!(context, selectedIndex);

    return MacosAdaptiveScaffold(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: destinations,
      child: content,
    );
  }

  Widget _buildCupertinoTabScaffold(BuildContext context) {
    // If child is provided (go_router pattern), use simple scaffold with tab bar
    if (child != null) {
      return CupertinoPageScaffold(
        child: Column(
          children: [
            Expanded(child: child!),
            CupertinoTabBar(
              items: destinations.map((dest) {
                return BottomNavigationBarItem(
                  icon: Icon(dest.cupertinoIcon),
                  activeIcon: Icon(dest.cupertinoSelectedIcon),
                  label: dest.label,
                );
              }).toList(),
              currentIndex: selectedIndex,
              onTap: onDestinationSelected,
            ),
          ],
        ),
      );
    }

    // Otherwise use full CupertinoTabScaffold (standalone pattern)
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: destinations.map((dest) {
          return BottomNavigationBarItem(
            icon: Icon(dest.cupertinoIcon),
            activeIcon: Icon(dest.cupertinoSelectedIcon),
            label: dest.label,
          );
        }).toList(),
        currentIndex: selectedIndex,
        onTap: onDestinationSelected,
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) => tabBuilder!(context, index),
        );
      },
    );
  }

  Widget _buildIPadSplitView(BuildContext context) {
    final cupertinoTheme = CupertinoTheme.of(context);

    // Determine content: prefer child, fall back to tabBuilder
    final content = child ?? tabBuilder!(context, selectedIndex);

    return Row(
      children: [
        // Sidebar
        Container(
          width: 280,
          decoration: BoxDecoration(
            color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
            border: Border(
              right: BorderSide(
                color: CupertinoColors.separator.resolveFrom(context),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'ReadWhere',
                    style: cupertinoTheme.textTheme.navLargeTitleTextStyle,
                  ),
                ),
                const SizedBox(height: 8),
                // Navigation items
                Expanded(
                  child: CupertinoListSection.insetGrouped(
                    children: destinations.asMap().entries.map((entry) {
                      final index = entry.key;
                      final dest = entry.value;
                      final isSelected = index == selectedIndex;

                      return CupertinoListTile(
                        leading: Icon(
                          isSelected
                              ? dest.cupertinoSelectedIcon
                              : dest.cupertinoIcon,
                          color: isSelected
                              ? cupertinoTheme.primaryColor
                              : CupertinoColors.label.resolveFrom(context),
                        ),
                        title: Text(
                          dest.label,
                          style: TextStyle(
                            color: isSelected
                                ? cupertinoTheme.primaryColor
                                : CupertinoColors.label.resolveFrom(context),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        backgroundColor: isSelected
                            ? cupertinoTheme.primaryColor.withValues(alpha: 0.1)
                            : null,
                        onTap: () => onDestinationSelected(index),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Content
        Expanded(child: content),
      ],
    );
  }

  Widget _buildMaterialScaffold(BuildContext context) {
    final content = child ?? tabBuilder!(context, selectedIndex);

    // Mobile layout: BottomNavigationBar
    if (context.isMobile) {
      return Scaffold(
        body: content,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: destinations.map((dest) {
            return NavigationDestination(
              icon: Icon(dest.icon),
              selectedIcon: Icon(dest.selectedIcon),
              label: dest.label,
            );
          }).toList(),
        ),
      );
    }

    // Desktop/Tablet layout: NavigationRail
    final isDesktop = context.isDesktop;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            extended: isDesktop,
            labelType: isDesktop
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.selected,
            destinations: destinations.map((dest) {
              return NavigationRailDestination(
                icon: Icon(dest.icon),
                selectedIcon: Icon(dest.selectedIcon),
                label: Text(dest.label),
              );
            }).toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: content),
        ],
      ),
    );
  }
}
