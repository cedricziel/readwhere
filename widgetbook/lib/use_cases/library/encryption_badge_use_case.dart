import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'package:readwhere/presentation/screens/library/widgets/encryption_badge.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';

@widgetbook.UseCase(name: 'Adobe DRM', type: EncryptionBadge, path: '[Library]')
Widget buildEncryptionBadgeAdobe(BuildContext context) {
  return Center(
    child: EncryptionBadge(
      encryptionType: EpubEncryptionType.adobeDrm,
      size: context.knobs.double.slider(
        label: 'Size',
        initialValue: 32,
        min: 16,
        max: 64,
      ),
    ),
  );
}

@widgetbook.UseCase(
  name: 'Apple FairPlay',
  type: EncryptionBadge,
  path: '[Library]',
)
Widget buildEncryptionBadgeFairPlay(BuildContext context) {
  return Center(
    child: EncryptionBadge(
      encryptionType: EpubEncryptionType.appleFairPlay,
      size: context.knobs.double.slider(
        label: 'Size',
        initialValue: 32,
        min: 16,
        max: 64,
      ),
    ),
  );
}

@widgetbook.UseCase(name: 'LCP', type: EncryptionBadge, path: '[Library]')
Widget buildEncryptionBadgeLcp(BuildContext context) {
  return Center(
    child: EncryptionBadge(
      encryptionType: EpubEncryptionType.lcp,
      size: context.knobs.double.slider(
        label: 'Size',
        initialValue: 32,
        min: 16,
        max: 64,
      ),
    ),
  );
}

@widgetbook.UseCase(
  name: 'Unknown DRM',
  type: EncryptionBadge,
  path: '[Library]',
)
Widget buildEncryptionBadgeUnknown(BuildContext context) {
  return Center(
    child: EncryptionBadge(
      encryptionType: EpubEncryptionType.unknown,
      size: context.knobs.double.slider(
        label: 'Size',
        initialValue: 32,
        min: 16,
        max: 64,
      ),
    ),
  );
}

@widgetbook.UseCase(name: 'All Types', type: EncryptionBadge, path: '[Library]')
Widget buildEncryptionBadgeAllTypes(BuildContext context) {
  final size = context.knobs.double.slider(
    label: 'Size',
    initialValue: 32,
    min: 16,
    max: 64,
  );

  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBadgeRow(context, 'Adobe DRM', EpubEncryptionType.adobeDrm, size),
        const SizedBox(height: 16),
        _buildBadgeRow(
          context,
          'Apple FairPlay',
          EpubEncryptionType.appleFairPlay,
          size,
        ),
        const SizedBox(height: 16),
        _buildBadgeRow(context, 'LCP', EpubEncryptionType.lcp, size),
        const SizedBox(height: 16),
        _buildBadgeRow(
          context,
          'Unknown DRM',
          EpubEncryptionType.unknown,
          size,
        ),
        const SizedBox(height: 16),
        _buildBadgeRow(
          context,
          'Font Obfuscation (hidden)',
          EpubEncryptionType.fontObfuscation,
          size,
        ),
        const SizedBox(height: 16),
        _buildBadgeRow(context, 'None (hidden)', EpubEncryptionType.none, size),
      ],
    ),
  );
}

Widget _buildBadgeRow(
  BuildContext context,
  String label,
  EpubEncryptionType type,
  double size,
) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      SizedBox(
        width: 180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(
              EncryptionBadge.getDescription(type),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 16),
      SizedBox(
        width: size + 8,
        height: size + 8,
        child: Center(
          child: EncryptionBadge(encryptionType: type, size: size),
        ),
      ),
    ],
  );
}

@widgetbook.UseCase(
  name: 'In Context (Book Cover)',
  type: EncryptionBadge,
  path: '[Library]',
)
Widget buildEncryptionBadgeInContext(BuildContext context) {
  final theme = Theme.of(context);

  return Center(
    child: SizedBox(
      width: 160,
      height: 240,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Mock book cover
            Container(
              color: theme.colorScheme.primaryContainer,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.menu_book,
                      size: 48,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Protected Book',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            // DRM badge
            const Positioned(
              top: 8,
              right: 8,
              child: EncryptionBadge(
                encryptionType: EpubEncryptionType.adobeDrm,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
