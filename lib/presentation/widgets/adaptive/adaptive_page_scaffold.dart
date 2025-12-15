import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../core/extensions/context_extensions.dart';
import 'adaptive_navigation_bar.dart';

/// An adaptive page scaffold that renders platform-appropriate structure.
///
/// On iOS/macOS: Uses [CupertinoPageScaffold] with native styling.
///
/// On other platforms: Uses [Scaffold] with Material Design styling.
///
/// Example:
/// ```dart
/// AdaptivePageScaffold(
///   title: 'Settings',
///   child: ListView(...),
/// )
/// ```
class AdaptivePageScaffold extends StatelessWidget {
  /// The title displayed in the navigation bar.
  final String? title;

  /// A custom navigation bar widget.
  ///
  /// If provided, this takes precedence over [title].
  /// Should be an [AdaptiveNavigationBar], [AppBar], or [CupertinoNavigationBar].
  final PreferredSizeWidget? navigationBar;

  /// The main content of the page.
  final Widget child;

  /// Background color of the page.
  final Color? backgroundColor;

  /// Whether to resize to avoid the keyboard.
  final bool resizeToAvoidBottomInset;

  /// Floating action button (Material only).
  final Widget? floatingActionButton;

  /// Bottom navigation bar (Material only).
  final Widget? bottomNavigationBar;

  /// Creates an adaptive page scaffold.
  const AdaptivePageScaffold({
    super.key,
    this.title,
    this.navigationBar,
    required this.child,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    // macOS: Use simple container since MacosScaffold handles chrome
    // Wrap with Material to support Material widgets like Slider
    if (!kIsWeb && Platform.isMacOS) {
      return _buildMacosScaffold(context);
    }

    if (context.useCupertino) {
      return _buildCupertinoScaffold(context);
    }
    return _buildMaterialScaffold(context);
  }

  Widget _buildMacosScaffold(BuildContext context) {
    // On macOS, we're inside MacosScaffold which provides the window chrome
    // but doesn't provide Material context, so wrap child with Material
    // Use MacosTheme.canvasColor for proper background color

    // Extract navigation bar properties if provided
    String? displayTitle = title;
    Widget? titleWidget;
    Widget? leading;
    List<Widget>? trailing;

    if (navigationBar is AdaptiveNavigationBar) {
      final navBar = navigationBar as AdaptiveNavigationBar;
      displayTitle = navBar.title ?? title;
      titleWidget = navBar.titleWidget;
      leading = navBar.leading;
      trailing = navBar.trailing;
    }

    final macosTheme = MacosTheme.of(context);

    return Material(
      color: backgroundColor ?? macosTheme.canvasColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toolbar for macOS content area
            _buildMacosToolbar(
              context,
              title: displayTitle,
              titleWidget: titleWidget,
              leading: leading,
              trailing: trailing,
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildMacosToolbar(
    BuildContext context, {
    String? title,
    Widget? titleWidget,
    Widget? leading,
    List<Widget>? trailing,
  }) {
    final theme = Theme.of(context);
    final hasToolbarContent =
        leading != null ||
        trailing != null && trailing.isNotEmpty ||
        title != null ||
        titleWidget != null;

    if (!hasToolbarContent) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          // Leading widget (back button)
          if (leading != null) ...[leading, const SizedBox(width: 8)],
          // Title
          Expanded(
            child:
                titleWidget ??
                (title != null
                    ? Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      )
                    : const SizedBox.shrink()),
          ),
          // Trailing actions
          if (trailing != null && trailing.isNotEmpty) ...[
            const SizedBox(width: 8),
            ...trailing,
          ],
        ],
      ),
    );
  }

  Widget _buildCupertinoScaffold(BuildContext context) {
    final navBar =
        navigationBar ??
        (title != null ? AdaptiveNavigationBar(title: title) : null);

    return CupertinoPageScaffold(
      navigationBar: navBar as ObstructingPreferredSizeWidget?,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      child: child,
    );
  }

  Widget _buildMaterialScaffold(BuildContext context) {
    final appBar =
        navigationBar ??
        (title != null ? AdaptiveNavigationBar(title: title) : null);

    return Scaffold(
      appBar: appBar,
      body: child,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

/// An adaptive scrollable page scaffold with a sliver app bar.
///
/// Provides a scrollable page with a collapsible navigation bar that
/// adapts to the platform's design language.
///
/// Example:
/// ```dart
/// AdaptiveScrollablePageScaffold(
///   title: 'Library',
///   largeTitle: true,
///   slivers: [
///     SliverList(...),
///   ],
/// )
/// ```
class AdaptiveScrollablePageScaffold extends StatelessWidget {
  /// The title displayed in the navigation bar.
  final String? title;

  /// A custom navigation bar widget.
  final Widget? navigationBar;

  /// The sliver widgets to display in the scroll view.
  final List<Widget> slivers;

  /// Background color of the page.
  final Color? backgroundColor;

  /// Whether to use large title style.
  final bool largeTitle;

  /// Widgets displayed at the trailing edge of the nav bar.
  final List<Widget>? trailing;

  /// Scroll controller for the scroll view.
  final ScrollController? controller;

  /// Floating action button (Material only).
  final Widget? floatingActionButton;

  /// Creates an adaptive scrollable page scaffold.
  const AdaptiveScrollablePageScaffold({
    super.key,
    this.title,
    this.navigationBar,
    required this.slivers,
    this.backgroundColor,
    this.largeTitle = false,
    this.trailing,
    this.controller,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    // macOS: Use simple scrollable with Material wrapper
    if (!kIsWeb && Platform.isMacOS) {
      return _buildMacosScaffold(context);
    }

    if (context.useCupertino) {
      return _buildCupertinoScaffold(context);
    }
    return _buildMaterialScaffold(context);
  }

  Widget _buildMacosScaffold(BuildContext context) {
    final theme = Theme.of(context);
    final macosTheme = MacosTheme.of(context);

    // Extract navigation bar properties if provided
    String? displayTitle = title;
    Widget? leadingWidget;
    List<Widget>? trailingWidgets = trailing;

    if (navigationBar is AdaptiveSliverNavigationBar) {
      final navBar = navigationBar as AdaptiveSliverNavigationBar;
      displayTitle = navBar.title ?? title;
      leadingWidget = navBar.leading;
      trailingWidgets = navBar.trailing ?? trailing;
    }

    final hasToolbarContent =
        leadingWidget != null ||
        trailingWidgets != null && trailingWidgets.isNotEmpty ||
        displayTitle != null;

    return Material(
      color: backgroundColor ?? macosTheme.canvasColor,
      child: SafeArea(
        child: CustomScrollView(
          controller: controller,
          slivers: [
            // Toolbar header for macOS
            if (hasToolbarContent)
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                  child: Row(
                    children: [
                      // Leading widget
                      if (leadingWidget != null) ...[
                        leadingWidget,
                        const SizedBox(width: 8),
                      ],
                      // Title
                      Expanded(
                        child: displayTitle != null
                            ? Text(
                                displayTitle,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              )
                            : const SizedBox.shrink(),
                      ),
                      // Trailing actions
                      if (trailingWidgets != null &&
                          trailingWidgets.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        ...trailingWidgets,
                      ],
                    ],
                  ),
                ),
              ),
            ...slivers,
          ],
        ),
      ),
    );
  }

  Widget _buildCupertinoScaffold(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      child: CustomScrollView(
        controller: controller,
        slivers: [
          if (navigationBar != null)
            navigationBar!
          else if (title != null)
            CupertinoSliverNavigationBar(
              largeTitle: Text(title!),
              trailing: trailing != null
                  ? Row(mainAxisSize: MainAxisSize.min, children: trailing!)
                  : null,
            ),
          ...slivers,
        ],
      ),
    );
  }

  Widget _buildMaterialScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: floatingActionButton,
      body: CustomScrollView(
        controller: controller,
        slivers: [
          if (navigationBar != null)
            navigationBar!
          else if (title != null)
            SliverAppBar(
              title: Text(title!),
              actions: trailing,
              pinned: true,
              floating: false,
              expandedHeight: largeTitle ? 120 : null,
              flexibleSpace: largeTitle
                  ? FlexibleSpaceBar(
                      title: Text(title!),
                      titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                    )
                  : null,
            ),
          ...slivers,
        ],
      ),
    );
  }
}
