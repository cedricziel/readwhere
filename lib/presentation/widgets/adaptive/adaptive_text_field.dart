import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

/// An adaptive text field that styles appropriately for the current platform.
///
/// On Apple platforms (iOS/macOS), displays an iOS-styled text field with
/// rounded corners and filled background.
/// On other platforms, displays a standard Material text field.
///
/// Example:
/// ```dart
/// AdaptiveTextField(
///   controller: _controller,
///   placeholder: 'Enter name',
///   onChanged: (value) => setState(() => _name = value),
/// )
/// ```
class AdaptiveTextField extends StatelessWidget {
  /// Controller for the text field.
  final TextEditingController? controller;

  /// Focus node for the text field.
  final FocusNode? focusNode;

  /// Placeholder text (hint) displayed when the field is empty.
  final String? placeholder;

  /// Label text displayed above the field (Material) or as placeholder (iOS).
  final String? label;

  /// Prefix icon displayed before the text.
  final IconData? prefixIcon;

  /// Suffix icon displayed after the text.
  final IconData? suffixIcon;

  /// Whether the text field should obscure text (for passwords).
  final bool obscureText;

  /// Keyboard type for the text field.
  final TextInputType? keyboardType;

  /// Text input action (done, next, search, etc.).
  final TextInputAction? textInputAction;

  /// Maximum number of lines.
  final int? maxLines;

  /// Minimum number of lines.
  final int? minLines;

  /// Whether the field is enabled.
  final bool enabled;

  /// Whether to autofocus the field.
  final bool autofocus;

  /// Callback when the text changes.
  final ValueChanged<String>? onChanged;

  /// Callback when editing is complete.
  final VoidCallback? onEditingComplete;

  /// Callback when the field is submitted.
  final ValueChanged<String>? onSubmitted;

  /// Validator function for form fields.
  final FormFieldValidator<String>? validator;

  /// Text capitalization behavior.
  final TextCapitalization textCapitalization;

  /// Autocorrect behavior.
  final bool autocorrect;

  /// Custom decoration (Material only, overrides platform styling).
  final InputDecoration? decoration;

  /// Whether the text field is read-only.
  final bool readOnly;

  /// Custom suffix widget (overrides suffixIcon).
  final Widget? suffix;

  /// Helper text displayed below the field (Material only).
  final String? helperText;

  /// Callback when the field is tapped.
  final VoidCallback? onTap;

  const AdaptiveTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.label,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.autofocus = false,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.decoration,
    this.readOnly = false,
    this.suffix,
    this.helperText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // If custom decoration is provided, use standard TextField
    if (decoration != null) {
      return _buildMaterialTextField(context);
    }

    if (context.useCupertino) {
      return _buildCupertinoTextField(context);
    }

    return _buildMaterialTextField(context);
  }

  /// Builds a Cupertino-styled text field.
  Widget _buildCupertinoTextField(BuildContext context) {
    final cupertinoTheme = CupertinoTheme.of(context);
    final brightness = cupertinoTheme.brightness ?? Brightness.light;
    final isDark = brightness == Brightness.dark;

    // Build suffix widget
    Widget? suffixWidget = suffix;
    if (suffixWidget == null && suffixIcon != null) {
      suffixWidget = Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Icon(suffixIcon, color: CupertinoColors.systemGrey),
      );
    }

    // Use validator wrapper if validator is provided
    if (validator != null) {
      final field = CupertinoTextFormFieldRow(
        controller: controller,
        focusNode: focusNode,
        placeholder: placeholder ?? label,
        prefix: prefixIcon != null
            ? Icon(prefixIcon, color: CupertinoColors.systemGrey)
            : null,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        maxLines: maxLines,
        minLines: minLines,
        enabled: enabled,
        autofocus: autofocus,
        onChanged: onChanged,
        onEditingComplete: onEditingComplete,
        onFieldSubmitted: onSubmitted,
        validator: validator,
        textCapitalization: textCapitalization,
        autocorrect: autocorrect,
        padding: EdgeInsets.zero,
        readOnly: readOnly,
      );
      // Wrap with GestureDetector if onTap is provided
      if (onTap != null) {
        return GestureDetector(onTap: onTap, child: field);
      }
      return field;
    }

    final field = CupertinoTextField(
      controller: controller,
      focusNode: focusNode,
      placeholder: placeholder ?? label,
      prefix: prefixIcon != null
          ? Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(prefixIcon, color: CupertinoColors.systemGrey),
            )
          : null,
      suffix: suffixWidget,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      minLines: minLines,
      enabled: enabled,
      autofocus: autofocus,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      onSubmitted: onSubmitted,
      textCapitalization: textCapitalization,
      autocorrect: autocorrect,
      readOnly: readOnly,
      decoration: BoxDecoration(
        color: isDark
            ? CupertinoColors.systemGrey6.darkColor
            : CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? CupertinoColors.systemGrey4.darkColor
              : CupertinoColors.systemGrey4,
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      style: TextStyle(
        color: isDark ? CupertinoColors.white : CupertinoColors.black,
      ),
      placeholderStyle: TextStyle(
        color: CupertinoColors.placeholderText.resolveFrom(context),
      ),
    );
    // Wrap with GestureDetector if onTap is provided
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: field);
    }
    return field;
  }

  /// Builds a Material text field.
  Widget _buildMaterialTextField(BuildContext context) {
    // Build suffix widget - custom suffix takes precedence over suffixIcon
    Widget? effectiveSuffix = suffix;
    if (effectiveSuffix == null && suffixIcon != null) {
      effectiveSuffix = Icon(suffixIcon);
    }

    final effectiveDecoration =
        decoration ??
        InputDecoration(
          labelText: label,
          hintText: placeholder,
          helperText: helperText,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          suffixIcon: effectiveSuffix,
        );

    // Use validator wrapper if validator is provided
    if (validator != null) {
      return TextFormField(
        controller: controller,
        focusNode: focusNode,
        decoration: effectiveDecoration,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        maxLines: maxLines,
        minLines: minLines,
        enabled: enabled,
        autofocus: autofocus,
        onChanged: onChanged,
        onEditingComplete: onEditingComplete,
        onFieldSubmitted: onSubmitted,
        validator: validator,
        textCapitalization: textCapitalization,
        autocorrect: autocorrect,
        readOnly: readOnly,
        onTap: onTap,
      );
    }

    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: effectiveDecoration,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      minLines: minLines,
      enabled: enabled,
      autofocus: autofocus,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      onSubmitted: onSubmitted,
      textCapitalization: textCapitalization,
      autocorrect: autocorrect,
      readOnly: readOnly,
      onTap: onTap,
    );
  }
}

/// An adaptive search field optimized for search input.
///
/// Displays as a [CupertinoSearchTextField] on Apple platforms and a
/// Material search field on other platforms.
class AdaptiveSearchField extends StatelessWidget {
  /// Controller for the search field.
  final TextEditingController? controller;

  /// Focus node for the search field.
  final FocusNode? focusNode;

  /// Placeholder text displayed when the field is empty.
  final String placeholder;

  /// Callback when the text changes.
  final ValueChanged<String>? onChanged;

  /// Callback when the search is submitted.
  final ValueChanged<String>? onSubmitted;

  /// Callback when the field is cleared or cancelled.
  final VoidCallback? onClear;

  /// Whether to autofocus the field.
  final bool autofocus;

  /// Whether the field is enabled.
  final bool enabled;

  const AdaptiveSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (context.useCupertino) {
      return CupertinoSearchTextField(
        controller: controller,
        focusNode: focusNode,
        placeholder: placeholder,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onSuffixTap: onClear,
        autofocus: autofocus,
        enabled: enabled,
      );
    }

    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        hintText: placeholder,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller?.text.isNotEmpty == true
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller?.clear();
                  onChanged?.call('');
                  onClear?.call();
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofocus: autofocus,
      enabled: enabled,
      textInputAction: TextInputAction.search,
    );
  }
}
