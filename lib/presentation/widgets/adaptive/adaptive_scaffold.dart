import 'package:flutter/material.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../router/routes.dart';

/// Adaptive scaffold that provides responsive navigation.
///
/// Automatically switches between NavigationRail (desktop/tablet)
/// and BottomNavigationBar (mobile) based on screen size.
///
/// - Desktop (>= 1200px): Extended NavigationRail on left
/// - Tablet (600-1200px): Collapsed NavigationRail on left
/// - Mobile (< 600px): BottomNavigationBar at bottom
class AdaptiveScaffold extends StatelessWidget {
  /// The currently selected destination index.
  final int selectedIndex;

  /// Callback when a navigation destination is selected.
  final ValueChanged<int> onDestinationSelected;

  /// The main content to display.
  final Widget child;

  /// Navigation destinations.
  final List<AppNavigationDestination> destinations;

  const AdaptiveScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    // Mobile layout: BottomNavigationBar
    if (context.isMobile) {
      return Scaffold(
        body: child,
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
                : NavigationRailLabelType.all,
            destinations: destinations.map((dest) {
              return NavigationRailDestination(
                icon: Icon(dest.icon),
                selectedIcon: Icon(dest.selectedIcon),
                label: Text(dest.label),
              );
            }).toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
