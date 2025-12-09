import 'package:flutter/material.dart';

import 'package:readwhere_plugin/readwhere_plugin.dart';

/// A badge widget that indicates a book's encryption/DRM status.
///
/// Shows different icons and colors based on the encryption type:
/// - DRM (Adobe, Apple FairPlay, LCP, unknown): Red lock icon
/// - Font obfuscation: No badge (not a reading restriction)
/// - None: No badge
class EncryptionBadge extends StatelessWidget {
  /// The type of encryption detected in the book.
  final EpubEncryptionType encryptionType;

  /// Optional size for the badge. Defaults to 24.
  final double size;

  const EncryptionBadge({
    super.key,
    required this.encryptionType,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show badge for non-DRM encryption types
    if (!_shouldShowBadge) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(size * 0.2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Icon(Icons.lock, size: size * 0.6, color: _badgeColor),
    );
  }

  /// Whether to show the badge based on encryption type.
  bool get _shouldShowBadge {
    switch (encryptionType) {
      case EpubEncryptionType.adobeDrm:
      case EpubEncryptionType.appleFairPlay:
      case EpubEncryptionType.lcp:
      case EpubEncryptionType.unknown:
        return true;
      case EpubEncryptionType.none:
      case EpubEncryptionType.fontObfuscation:
        return false;
    }
  }

  /// Get the badge color based on encryption type.
  Color get _badgeColor {
    switch (encryptionType) {
      case EpubEncryptionType.adobeDrm:
      case EpubEncryptionType.appleFairPlay:
      case EpubEncryptionType.lcp:
        return Colors.red.shade300;
      case EpubEncryptionType.unknown:
        return Colors.orange.shade300;
      case EpubEncryptionType.none:
      case EpubEncryptionType.fontObfuscation:
        return Colors.transparent;
    }
  }

  /// Get a human-readable description of the encryption type.
  static String getDescription(EpubEncryptionType type) {
    switch (type) {
      case EpubEncryptionType.adobeDrm:
        return 'Protected by Adobe DRM';
      case EpubEncryptionType.appleFairPlay:
        return 'Protected by Apple FairPlay';
      case EpubEncryptionType.lcp:
        return 'Protected by Readium LCP';
      case EpubEncryptionType.unknown:
        return 'Protected by unknown DRM';
      case EpubEncryptionType.fontObfuscation:
        return 'Contains obfuscated fonts';
      case EpubEncryptionType.none:
        return 'No protection';
    }
  }
}
