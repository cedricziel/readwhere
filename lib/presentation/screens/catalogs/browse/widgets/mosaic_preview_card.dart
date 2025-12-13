import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';

/// A card widget that displays a 2x2 mosaic of cover images from child entries.
///
/// Used for navigation sections (like "On-Deck", "Recently Updated") to provide
/// a visual preview of the content inside before navigating.
class MosaicPreviewCard extends StatelessWidget {
  /// The parent navigation entry.
  final CatalogEntry entry;

  /// Cover URLs from child entries (max 4 displayed).
  final List<String> childCoverUrls;

  /// Called when the card is tapped.
  final VoidCallback onTap;

  /// Optional count of child items (shown as badge).
  final int? childCount;

  /// Whether the child covers are still loading.
  final bool isLoading;

  const MosaicPreviewCard({
    super.key,
    required this.entry,
    required this.childCoverUrls,
    required this.onTap,
    this.childCount,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background: mosaic or fallback
            _buildMosaicOrFallback(context),

            // Loading indicator overlay
            if (isLoading)
              Container(
                color: theme.colorScheme.surface.withValues(alpha: 0.5),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),

            // Title overlay at bottom
            _buildTitleOverlay(context),

            // Item count badge (top-right)
            if (childCount != null && childCount! > 0)
              Positioned(top: 8, right: 8, child: _buildCountBadge(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildMosaicOrFallback(BuildContext context) {
    // If we have child covers, show mosaic
    if (childCoverUrls.isNotEmpty) {
      return _buildMosaic(context);
    }

    // If parent entry has its own cover, show it
    final parentCover = entry.thumbnailUrl ?? entry.coverUrl;
    if (parentCover != null && parentCover.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: parentCover,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildPlaceholder(context),
        errorWidget: (context, url, error) => _buildPlaceholder(context),
      );
    }

    // Fallback to folder icon placeholder
    return _buildPlaceholder(context);
  }

  Widget _buildMosaic(BuildContext context) {
    // Take up to 4 images for 2x2 grid
    final images = childCoverUrls.take(4).toList();

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: 4, // Always 4 cells for consistent layout
      itemBuilder: (context, index) {
        if (index < images.length) {
          return CachedNetworkImage(
            imageUrl: images[index],
            fit: BoxFit.cover,
            placeholder: (context, url) => _buildCellPlaceholder(context),
            errorWidget: (context, url, error) =>
                _buildCellPlaceholder(context),
          );
        }
        // Empty cell placeholder for remaining slots
        return _buildCellPlaceholder(context);
      },
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.secondaryContainer,
      child: Icon(
        Icons.folder,
        size: 48,
        color: theme.colorScheme.onSecondaryContainer,
      ),
    );
  }

  Widget _buildCellPlaceholder(BuildContext context) {
    final theme = Theme.of(context);

    return Container(color: theme.colorScheme.surfaceContainerHighest);
  }

  Widget _buildTitleOverlay(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
        child: Text(
          entry.title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildCountBadge(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$childCount',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// List tile version of mosaic preview for list view layouts.
class MosaicPreviewListTile extends StatelessWidget {
  /// The parent navigation entry.
  final CatalogEntry entry;

  /// Cover URLs from child entries (max 4 displayed in mini mosaic).
  final List<String> childCoverUrls;

  /// Called when the tile is tapped.
  final VoidCallback onTap;

  /// Optional count of child items.
  final int? childCount;

  /// Whether the child covers are still loading.
  final bool isLoading;

  const MosaicPreviewListTile({
    super.key,
    required this.entry,
    required this.childCoverUrls,
    required this.onTap,
    this.childCount,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: SizedBox(
        width: 48,
        height: 64,
        child: _buildMiniMosaic(context),
      ),
      title: Text(entry.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: childCount != null
          ? Text('$childCount items')
          : entry.subtitle != null
          ? Text(entry.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
    );
  }

  Widget _buildMiniMosaic(BuildContext context) {
    final theme = Theme.of(context);

    if (childCoverUrls.isEmpty) {
      // Fallback to folder icon
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          Icons.folder,
          color: theme.colorScheme.onSecondaryContainer,
        ),
      );
    }

    // Show 2x2 mini mosaic
    final images = childCoverUrls.take(4).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 1,
          crossAxisSpacing: 1,
        ),
        itemCount: 4,
        itemBuilder: (context, index) {
          if (index < images.length) {
            return CachedNetworkImage(
              imageUrl: images[index],
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  Container(color: theme.colorScheme.surfaceContainerHighest),
              errorWidget: (context, url, error) =>
                  Container(color: theme.colorScheme.surfaceContainerHighest),
            );
          }
          return Container(color: theme.colorScheme.surfaceContainerHighest);
        },
      ),
    );
  }
}
