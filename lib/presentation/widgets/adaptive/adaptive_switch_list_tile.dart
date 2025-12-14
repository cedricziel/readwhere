// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

/// An adaptive switch list tile that renders platform-appropriate styling.
///
/// On iOS/macOS: Uses [CupertinoListTile] with [CupertinoSwitch].
///
/// On other platforms: Uses [SwitchListTile] with Material Design styling.
///
/// Example:
/// ```dart
/// AdaptiveSwitchListTile(
///   title: Text('Dark Mode'),
///   subtitle: Text('Use dark theme'),
///   value: isDarkMode,
///   onChanged: (value) => setDarkMode(value),
/// )
/// ```
class AdaptiveSwitchListTile extends StatelessWidget {
  /// The primary content of the list tile.
  final Widget title;

  /// Additional content displayed below the title.
  final Widget? subtitle;

  /// Widget displayed before the title.
  final Widget? leading;

  /// Whether the switch is on or off.
  final bool value;

  /// Called when the user toggles the switch.
  final ValueChanged<bool>? onChanged;

  /// Whether the tile is enabled for interaction.
  final bool enabled;

  /// The color to use when the switch is on.
  final Color? activeColor;

  /// Creates an adaptive switch list tile.
  const AdaptiveSwitchListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    required this.value,
    this.onChanged,
    this.enabled = true,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    if (context.useCupertino) {
      return _buildCupertinoTile(context);
    }
    return _buildMaterialTile(context);
  }

  Widget _buildCupertinoTile(BuildContext context) {
    return CupertinoListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: CupertinoSwitch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeTrackColor: activeColor,
      ),
      onTap: enabled && onChanged != null ? () => onChanged!(!value) : null,
    );
  }

  Widget _buildMaterialTile(BuildContext context) {
    return SwitchListTile(
      title: title,
      subtitle: subtitle,
      secondary: leading,
      value: value,
      onChanged: enabled ? onChanged : null,
      activeTrackColor: activeColor,
    );
  }
}

/// An adaptive checkbox list tile that renders platform-appropriate styling.
///
/// On iOS/macOS: Uses [CupertinoListTile] with a checkmark icon.
///
/// On other platforms: Uses [CheckboxListTile] with Material Design styling.
///
/// Example:
/// ```dart
/// AdaptiveCheckboxListTile(
///   title: Text('Enable notifications'),
///   value: notificationsEnabled,
///   onChanged: (value) => setNotifications(value),
/// )
/// ```
class AdaptiveCheckboxListTile extends StatelessWidget {
  /// The primary content of the list tile.
  final Widget title;

  /// Additional content displayed below the title.
  final Widget? subtitle;

  /// Widget displayed before the title.
  final Widget? leading;

  /// Whether the checkbox is checked.
  final bool value;

  /// Called when the user toggles the checkbox.
  final ValueChanged<bool?>? onChanged;

  /// Whether the tile is enabled for interaction.
  final bool enabled;

  /// Creates an adaptive checkbox list tile.
  const AdaptiveCheckboxListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    required this.value,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (context.useCupertino) {
      return _buildCupertinoTile(context);
    }
    return _buildMaterialTile(context);
  }

  Widget _buildCupertinoTile(BuildContext context) {
    return CupertinoListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: value
          ? Icon(
              CupertinoIcons.checkmark,
              color: CupertinoTheme.of(context).primaryColor,
            )
          : null,
      onTap: enabled && onChanged != null ? () => onChanged!(!value) : null,
    );
  }

  Widget _buildMaterialTile(BuildContext context) {
    return CheckboxListTile(
      title: title,
      subtitle: subtitle,
      secondary: leading,
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }
}

/// An adaptive radio list tile that renders platform-appropriate styling.
///
/// On iOS/macOS: Uses [CupertinoListTile] with a checkmark for selected item.
///
/// On other platforms: Uses [RadioListTile] with Material Design styling.
///
/// Example:
/// ```dart
/// AdaptiveRadioListTile<ThemeMode>(
///   title: Text('Dark'),
///   value: ThemeMode.dark,
///   groupValue: currentThemeMode,
///   onChanged: (value) => setThemeMode(value),
/// )
/// ```
class AdaptiveRadioListTile<T> extends StatelessWidget {
  /// The primary content of the list tile.
  final Widget title;

  /// Additional content displayed below the title.
  final Widget? subtitle;

  /// Widget displayed before the title (on Material).
  final Widget? secondary;

  /// The value represented by this radio tile.
  final T value;

  /// The currently selected value for this group of radio tiles.
  final T? groupValue;

  /// Called when the user selects this radio tile.
  final ValueChanged<T?>? onChanged;

  /// Whether the tile is enabled for interaction.
  final bool enabled;

  /// Creates an adaptive radio list tile.
  const AdaptiveRadioListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.secondary,
    required this.value,
    required this.groupValue,
    this.onChanged,
    this.enabled = true,
  });

  bool get _isSelected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    if (context.useCupertino) {
      return _buildCupertinoTile(context);
    }
    return _buildMaterialTile(context);
  }

  Widget _buildCupertinoTile(BuildContext context) {
    return CupertinoListTile(
      title: title,
      subtitle: subtitle,
      trailing: _isSelected
          ? Icon(
              CupertinoIcons.checkmark,
              color: CupertinoTheme.of(context).primaryColor,
            )
          : null,
      onTap: enabled && onChanged != null ? () => onChanged!(value) : null,
    );
  }

  Widget _buildMaterialTile(BuildContext context) {
    return RadioListTile<T>(
      title: title,
      subtitle: subtitle,
      secondary: secondary,
      value: value,
      groupValue: groupValue,
      onChanged: enabled ? onChanged : null,
    );
  }
}
