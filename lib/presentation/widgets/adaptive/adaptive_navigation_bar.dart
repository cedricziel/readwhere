import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

/// An adaptive app bar/navigation bar that renders platform-appropriate styling.
///
/// On iOS/macOS: Uses [CupertinoNavigationBar] with native styling.
///
/// On other platforms: Uses [AppBar] with Material Design styling.
///
/// Example:
/// ```dart
/// AdaptiveNavigationBar(
///   title: 'Settings',
///   leading: BackButton(),
///   trailing: [
///     IconButton(icon: Icon(Icons.search), onPressed: _search),
///   ],
/// )
/// ```
class AdaptiveNavigationBar extends StatelessWidget
    implements PreferredSizeWidget, ObstructingPreferredSizeWidget {
  /// The title displayed in the center of the bar.
  final String? title;

  /// A custom widget to use as the title instead of text.
  final Widget? titleWidget;

  /// Widget displayed at the leading edge (typically back button).
  final Widget? leading;

  /// Widgets displayed at the trailing edge.
  final List<Widget>? trailing;

  /// Whether to automatically imply a leading back button.
  final bool automaticallyImplyLeading;

  /// Background color of the bar.
  final Color? backgroundColor;

  /// Whether to use large title style on iOS.
  ///
  /// When true, the title is displayed in a larger font below the nav bar
  /// and collapses into the bar on scroll.
  final bool largeTitle;

  /// The brightness to use for the status bar icons.
  final Brightness? brightness;

  /// Additional bottom widget (e.g., TabBar).
  final PreferredSizeWidget? bottom;

  /// Creates an adaptive navigation bar.
  const AdaptiveNavigationBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.trailing,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.largeTitle = false,
    this.brightness,
    this.bottom,
  });

  @override
  Size get preferredSize {
    double height = kToolbarHeight;
    if (bottom != null) {
      height += bottom!.preferredSize.height;
    }
    return Size.fromHeight(height);
  }

  @override
  bool shouldFullyObstruct(BuildContext context) {
    final Color effectiveBackgroundColor =
        backgroundColor ?? CupertinoTheme.of(context).barBackgroundColor;
    return effectiveBackgroundColor.a >= 1.0;
  }

  @override
  Widget build(BuildContext context) {
    if (context.useCupertino) {
      return _buildCupertinoBar(context);
    }
    return _buildMaterialBar(context);
  }

  Widget _buildCupertinoBar(BuildContext context) {
    Widget? trailingWidget;
    if (trailing != null && trailing!.isNotEmpty) {
      if (trailing!.length == 1) {
        trailingWidget = trailing!.first;
      } else {
        trailingWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: trailing!,
        );
      }
    }

    return CupertinoNavigationBar(
      middle: titleWidget ?? (title != null ? Text(title!) : null),
      leading: leading,
      trailing: trailingWidget,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor,
      brightness: brightness,
    );
  }

  Widget _buildMaterialBar(BuildContext context) {
    return AppBar(
      title: titleWidget ?? (title != null ? Text(title!) : null),
      leading: leading,
      actions: trailing,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor,
      bottom: bottom,
    );
  }
}

/// An adaptive sliver app bar for use in scrollable views.
///
/// On iOS/macOS: Uses [CupertinoSliverNavigationBar] with large title support.
///
/// On other platforms: Uses [SliverAppBar] with Material Design styling.
///
/// Example:
/// ```dart
/// CustomScrollView(
///   slivers: [
///     AdaptiveSliverNavigationBar(
///       title: 'Library',
///       largeTitle: true,
///     ),
///     SliverList(...),
///   ],
/// )
/// ```
class AdaptiveSliverNavigationBar extends StatelessWidget {
  /// The title displayed in the bar.
  final String? title;

  /// A custom widget to use as the title.
  final Widget? titleWidget;

  /// Widget displayed at the leading edge.
  final Widget? leading;

  /// Widgets displayed at the trailing edge.
  final List<Widget>? trailing;

  /// Whether to automatically imply a leading back button.
  final bool automaticallyImplyLeading;

  /// Background color of the bar.
  final Color? backgroundColor;

  /// Whether to use large title style (iOS) or expanded title (Material).
  final bool largeTitle;

  /// Whether the bar should remain visible when scrolled.
  final bool pinned;

  /// Whether the bar should become visible as soon as the user scrolls up.
  final bool floating;

  /// Creates an adaptive sliver navigation bar.
  const AdaptiveSliverNavigationBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.trailing,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.largeTitle = false,
    this.pinned = true,
    this.floating = false,
  });

  @override
  Widget build(BuildContext context) {
    if (context.useCupertino) {
      return _buildCupertinoBar(context);
    }
    return _buildMaterialBar(context);
  }

  Widget _buildCupertinoBar(BuildContext context) {
    Widget? trailingWidget;
    if (trailing != null && trailing!.isNotEmpty) {
      if (trailing!.length == 1) {
        trailingWidget = trailing!.first;
      } else {
        trailingWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: trailing!,
        );
      }
    }

    return CupertinoSliverNavigationBar(
      largeTitle: titleWidget ?? (title != null ? Text(title!) : null),
      leading: leading,
      trailing: trailingWidget,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor,
    );
  }

  Widget _buildMaterialBar(BuildContext context) {
    return SliverAppBar(
      title: titleWidget ?? (title != null ? Text(title!) : null),
      leading: leading,
      actions: trailing,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor,
      pinned: pinned,
      floating: floating,
      expandedHeight: largeTitle ? 120 : null,
      flexibleSpace: largeTitle
          ? FlexibleSpaceBar(
              title: titleWidget ?? (title != null ? Text(title!) : null),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            )
          : null,
    );
  }
}
