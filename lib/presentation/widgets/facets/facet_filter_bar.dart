import 'package:flutter/material.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';

/// A horizontal filter bar displaying active facets as chips.
///
/// Shows active facets with remove icons. When no facets are active,
/// shows a single "Filters" chip to open the selection sheet.
class FacetFilterBar extends StatelessWidget {
  /// Available facet groups.
  final List<CatalogFacetGroup> facetGroups;

  /// Called when a facet chip is tapped.
  ///
  /// In catalog mode: Navigate to facet URL.
  /// In library mode: Open facet selection sheet.
  final void Function(CatalogFacet facet, CatalogFacetGroup group) onFacetTap;

  /// Called when the "Filters" button is tapped.
  final VoidCallback? onShowFilters;

  /// Called when "Clear all" is requested.
  final VoidCallback? onClearAll;

  /// Whether this is catalog mode (single-select navigate) or library mode
  /// (multi-select local).
  final bool isCatalogMode;

  const FacetFilterBar({
    super.key,
    required this.facetGroups,
    required this.onFacetTap,
    this.onShowFilters,
    this.onClearAll,
    this.isCatalogMode = true,
  });

  @override
  Widget build(BuildContext context) {
    final activeFacets = _getActiveFacets();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Show active facets as chips with delete icon
            ...activeFacets.map(
              (record) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildActiveFacetChip(context, record.$1, record.$2),
              ),
            ),

            // Show filter button
            _buildFilterButton(context, activeFacets.isNotEmpty),

            // Show clear all if there are active facets
            if (activeFacets.isNotEmpty && onClearAll != null) ...[
              const SizedBox(width: 8),
              _buildClearAllChip(context),
            ],
          ],
        ),
      ),
    );
  }

  /// Get all active facets with their parent group.
  List<(CatalogFacet, CatalogFacetGroup)> _getActiveFacets() {
    final activeFacets = <(CatalogFacet, CatalogFacetGroup)>[];
    for (final group in facetGroups) {
      for (final facet in group.facets) {
        if (facet.isActive) {
          activeFacets.add((facet, group));
        }
      }
    }
    return activeFacets;
  }

  Widget _buildActiveFacetChip(
    BuildContext context,
    CatalogFacet facet,
    CatalogFacetGroup group,
  ) {
    final theme = Theme.of(context);

    return FilterChip(
      selected: true,
      label: Text(
        '${group.name}: ${facet.title}',
        style: TextStyle(color: theme.colorScheme.onPrimary),
      ),
      backgroundColor: theme.colorScheme.primary,
      selectedColor: theme.colorScheme.primary,
      checkmarkColor: theme.colorScheme.onPrimary,
      deleteIcon: Icon(
        Icons.close,
        size: 18,
        color: theme.colorScheme.onPrimary,
      ),
      onDeleted: () => onFacetTap(facet, group),
      onSelected: (_) => onFacetTap(facet, group),
    );
  }

  Widget _buildFilterButton(BuildContext context, bool hasActiveFilters) {
    return FilterChip(
      avatar: const Icon(Icons.filter_list, size: 18),
      label: Text(hasActiveFilters ? 'More' : 'Filters'),
      onSelected: (_) => onShowFilters?.call(),
    );
  }

  Widget _buildClearAllChip(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.clear_all, size: 18),
      label: const Text('Clear'),
      onPressed: onClearAll,
    );
  }
}
