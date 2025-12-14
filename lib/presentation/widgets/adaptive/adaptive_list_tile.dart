import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

/// An adaptive list tile that renders platform-appropriate styling.
///
/// On iOS/macOS: Uses [CupertinoListTile] with native disclosure chevrons
/// and proper iOS spacing and tap feedback.
///
/// On other platforms: Uses [ListTile] with Material Design styling.
///
/// Example:
/// ```dart
/// AdaptiveListTile(
///   leading: Icon(Icons.palette),
///   title: Text('Theme'),
///   subtitle: Text('Choose your preferred theme'),
///   additionalInfo: Text('System'),
///   showDisclosureIndicator: true,
///   onTap: () => _showThemePicker(),
/// )
/// ```
class AdaptiveListTile extends StatelessWidget {
  /// Widget displayed before the title.
  final Widget? leading;

  /// The primary content of the list tile.
  final Widget title;

  /// Additional content displayed below the title.
  final Widget? subtitle;

  /// Additional info displayed on the trailing side (iOS only).
  ///
  /// On iOS, this appears before the disclosure chevron in a muted color.
  /// On Material, this is ignored (use [trailing] instead).
  final Widget? additionalInfo;

  /// Widget displayed after the title/additional info.
  ///
  /// On iOS with [showDisclosureIndicator], this is placed before the chevron.
  /// On Material, this replaces any auto-generated trailing widget.
  final Widget? trailing;

  /// Whether to show a disclosure indicator (chevron).
  ///
  /// On iOS: Shows [CupertinoListTileChevron].
  /// On Material: Shows [Icons.chevron_right].
  final bool showDisclosureIndicator;

  /// Called when the tile is tapped.
  final VoidCallback? onTap;

  /// Called when the tile is long-pressed.
  final VoidCallback? onLongPress;

  /// Whether the tile is enabled for interaction.
  final bool enabled;

  /// Background color for the tile.
  final Color? backgroundColor;

  /// Creates an adaptive list tile.
  const AdaptiveListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.additionalInfo,
    this.trailing,
    this.showDisclosureIndicator = false,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (context.useCupertino) {
      return _buildCupertinoTile(context);
    }
    return _buildMaterialTile(context);
  }

  Widget _buildCupertinoTile(BuildContext context) {
    Widget? trailingWidget;

    if (showDisclosureIndicator) {
      trailingWidget = const CupertinoListTileChevron();
    } else if (trailing != null) {
      trailingWidget = trailing;
    }

    return CupertinoListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      additionalInfo: additionalInfo,
      trailing: trailingWidget,
      onTap: enabled ? onTap : null,
      backgroundColor: backgroundColor,
    );
  }

  Widget _buildMaterialTile(BuildContext context) {
    Widget? trailingWidget;

    if (trailing != null) {
      trailingWidget = trailing;
    } else if (showDisclosureIndicator) {
      trailingWidget = const Icon(Icons.chevron_right);
    }

    // For Material, show additionalInfo as part of subtitle or trailing
    Widget? effectiveSubtitle = subtitle;
    if (additionalInfo != null && subtitle == null) {
      effectiveSubtitle = additionalInfo;
    }

    return ListTile(
      leading: leading,
      title: title,
      subtitle: effectiveSubtitle,
      trailing: trailingWidget,
      onTap: enabled ? onTap : null,
      onLongPress: enabled ? onLongPress : null,
      enabled: enabled,
      tileColor: backgroundColor,
    );
  }
}

/// An adaptive list tile with a navigation link style.
///
/// This is a convenience widget for common navigation patterns.
/// Always shows a disclosure indicator and handles tap navigation.
class AdaptiveNavigationListTile extends StatelessWidget {
  /// Widget displayed before the title.
  final Widget? leading;

  /// The primary content of the list tile.
  final Widget title;

  /// Additional content displayed below the title.
  final Widget? subtitle;

  /// Value displayed on the trailing side (e.g., current selection).
  final String? value;

  /// Called when the tile is tapped.
  final VoidCallback onTap;

  /// Creates an adaptive navigation list tile.
  const AdaptiveNavigationListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      additionalInfo: value != null ? Text(value!) : null,
      showDisclosureIndicator: true,
      onTap: onTap,
    );
  }
}
