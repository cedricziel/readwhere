import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'package:readwhere/presentation/widgets/common/app_logo.dart';

@widgetbook.UseCase(name: 'Color Variant', type: AppLogo, path: '[Common]')
Widget buildAppLogoColor(BuildContext context) {
  return Center(
    child: AppLogo(
      variant: AppLogoVariant.color,
      size: context.knobs.double.slider(
        label: 'Size',
        initialValue: 64,
        min: 24,
        max: 200,
      ),
    ),
  );
}

@widgetbook.UseCase(name: 'Mono Variant', type: AppLogo, path: '[Common]')
Widget buildAppLogoMono(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;

  return Center(
    child: AppLogo(
      variant: AppLogoVariant.mono,
      size: context.knobs.double.slider(
        label: 'Size',
        initialValue: 64,
        min: 24,
        max: 200,
      ),
      color:
          context.knobs.boolean(label: 'Use Custom Color', initialValue: false)
          ? colorScheme.primary
          : null,
    ),
  );
}

@widgetbook.UseCase(name: 'Size Comparison', type: AppLogo, path: '[Common]')
Widget buildAppLogoSizeComparison(BuildContext context) {
  return Center(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 32),
            const SizedBox(height: 8),
            Text('32px', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 48),
            const SizedBox(height: 8),
            Text('48px', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 64),
            const SizedBox(height: 8),
            Text('64px', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 96),
            const SizedBox(height: 8),
            Text('96px', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ],
    ),
  );
}

@widgetbook.UseCase(name: 'In AppBar', type: AppLogo, path: '[Common]')
Widget buildAppLogoInAppBar(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      leading: const Padding(
        padding: EdgeInsets.all(8.0),
        child: AppLogo(size: 40),
      ),
      title: const Text('ReadWhere'),
    ),
    body: const Center(child: Text('Logo in AppBar example')),
  );
}
