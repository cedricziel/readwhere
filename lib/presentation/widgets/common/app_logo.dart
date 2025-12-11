import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Variant styles for the ReadWhere app logo.
enum AppLogoVariant {
  /// Full color gradient version.
  color,

  /// Monochrome version that uses the current text color.
  mono,
}

/// ReadWhere app logo widget.
///
/// Displays the SVG app logo with configurable size and style variant.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 48.0,
    this.variant = AppLogoVariant.color,
    this.color,
    this.semanticLabel = 'ReadWhere logo',
  });

  /// The size of the logo (width and height).
  final double size;

  /// The logo variant to display.
  final AppLogoVariant variant;

  /// Custom color for the mono variant. If null, uses the current icon color.
  final Color? color;

  /// Semantic label for accessibility.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final assetPath = variant == AppLogoVariant.color
        ? 'assets/icons/readwhere_logo.svg'
        : 'assets/icons/readwhere_logo_mono.svg';

    final colorFilter = variant == AppLogoVariant.mono
        ? ColorFilter.mode(
            color ??
                IconTheme.of(context).color ??
                Theme.of(context).colorScheme.onSurface,
            BlendMode.srcIn,
          )
        : null;

    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      semanticsLabel: semanticLabel,
      colorFilter: colorFilter,
    );
  }
}
