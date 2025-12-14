import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

/// An adaptive grouped list section that renders platform-appropriate styling.
///
/// On iOS/macOS: Uses [CupertinoListSection.insetGrouped] with rounded corners
/// and the characteristic gray background between sections.
///
/// On other platforms: Uses a [Column] with a styled header, maintaining
/// Material Design visual hierarchy.
///
/// Example:
/// ```dart
/// AdaptiveListSection(
///   header: 'Appearance',
///   footer: 'Choose how the app looks',
///   children: [
///     AdaptiveListTile(title: Text('Theme')),
///     AdaptiveListTile(title: Text('Font Size')),
///   ],
/// )
/// ```
class AdaptiveListSection extends StatelessWidget {
  /// The header text displayed above the section.
  final String? header;

  /// The footer text displayed below the section.
  final String? footer;

  /// The list items within this section.
  ///
  /// For iOS, these should be [CupertinoListTile] or [AdaptiveListTile] widgets.
  /// For Material, these should be [ListTile] or [AdaptiveListTile] widgets.
  final List<Widget> children;

  /// Additional padding around the section.
  final EdgeInsetsGeometry? margin;

  /// Creates an adaptive list section.
  const AdaptiveListSection({
    super.key,
    this.header,
    this.footer,
    required this.children,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    if (context.useCupertino) {
      return _buildCupertinoSection(context);
    }
    return _buildMaterialSection(context);
  }

  Widget _buildCupertinoSection(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: CupertinoListSection.insetGrouped(
        header: header != null ? Text(header!) : null,
        footer: footer != null ? Text(footer!) : null,
        children: children,
      ),
    );
  }

  Widget _buildMaterialSection(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                header!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
          ...children,
          if (footer != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                footer!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
