import 'package:flutter/material.dart';

/// A compact indicator showing cache status for OPDS feeds.
///
/// Displays whether content is from cache, how old the cache is,
/// and provides a refresh button to force network fetch.
class CacheStatusIndicator extends StatelessWidget {
  /// Whether the current content is from cache
  final bool isFromCache;

  /// Whether the cache is still fresh (not expired)
  final bool isFresh;

  /// Human-readable text describing cache age (e.g., "Cached 2h ago")
  final String cacheAgeText;

  /// Callback when refresh is requested
  final VoidCallback? onRefresh;

  /// Whether a refresh is currently in progress
  final bool isRefreshing;

  const CacheStatusIndicator({
    super.key,
    required this.isFromCache,
    required this.isFresh,
    required this.cacheAgeText,
    this.onRefresh,
    this.isRefreshing = false,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show anything if content is not from cache
    if (!isFromCache) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use tertiary for fresh cache, error for stale
    final indicatorColor = isFresh
        ? colorScheme.tertiaryContainer
        : colorScheme.errorContainer;
    final textColor = isFresh
        ? colorScheme.onTertiaryContainer
        : colorScheme.onErrorContainer;
    final iconColor = textColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: indicatorColor,
      child: Row(
        children: [
          Icon(
            isFresh ? Icons.cloud_done : Icons.cloud_off,
            size: 16,
            color: iconColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              cacheAgeText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onRefresh != null)
            isRefreshing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: textColor,
                    ),
                  )
                : InkWell(
                    onTap: onRefresh,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh, size: 16, color: iconColor),
                          const SizedBox(width: 4),
                          Text(
                            'Refresh',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
        ],
      ),
    );
  }
}

/// A compact chip version of the cache indicator for tight spaces.
class CacheStatusChip extends StatelessWidget {
  /// Whether the current content is from cache
  final bool isFromCache;

  /// Whether the cache is still fresh (not expired)
  final bool isFresh;

  /// Human-readable text describing cache age
  final String cacheAgeText;

  const CacheStatusChip({
    super.key,
    required this.isFromCache,
    required this.isFresh,
    required this.cacheAgeText,
  });

  @override
  Widget build(BuildContext context) {
    if (!isFromCache) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final chipColor = isFresh
        ? colorScheme.tertiaryContainer
        : colorScheme.errorContainer;
    final textColor = isFresh
        ? colorScheme.onTertiaryContainer
        : colorScheme.onErrorContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFresh ? Icons.cloud_done : Icons.cloud_off,
            size: 12,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            cacheAgeText,
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
