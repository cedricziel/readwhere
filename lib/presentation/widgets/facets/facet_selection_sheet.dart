import 'package:flutter/material.dart';
import 'package:readwhere_plugin/readwhere_plugin.dart';

/// Bottom sheet for selecting facets from available groups.
///
/// In catalog mode: Tap a facet to immediately navigate (single-select).
/// In library mode: Toggle multiple facets, then apply (multi-select).
class FacetSelectionSheet extends StatefulWidget {
  /// Available facet groups.
  final List<CatalogFacetGroup> facetGroups;

  /// Called when a facet is selected (catalog mode: immediate navigation).
  final void Function(CatalogFacet facet, CatalogFacetGroup group)
  onFacetSelected;

  /// Whether this is catalog mode (single-select navigate) or library mode
  /// (multi-select local).
  final bool isCatalogMode;

  /// Called when "Clear all" is tapped.
  final VoidCallback? onClear;

  /// For library mode: currently selected facet IDs by group.
  /// Key: group name, Value: set of facet hrefs.
  final Map<String, Set<String>>? selectedFacets;

  /// For library mode: called when Apply is pressed with new selections.
  final void Function(Map<String, Set<String>> selections)? onApply;

  const FacetSelectionSheet({
    super.key,
    required this.facetGroups,
    required this.onFacetSelected,
    this.isCatalogMode = true,
    this.onClear,
    this.selectedFacets,
    this.onApply,
  });

  @override
  State<FacetSelectionSheet> createState() => _FacetSelectionSheetState();
}

class _FacetSelectionSheetState extends State<FacetSelectionSheet> {
  // For library mode: local selections before Apply
  late Map<String, Set<String>> _localSelections;

  @override
  void initState() {
    super.initState();
    // Copy current selections for library mode editing
    _localSelections = widget.selectedFacets != null
        ? Map.from(
            widget.selectedFacets!.map(
              (k, v) => MapEntry(k, Set<String>.from(v)),
            ),
          )
        : {};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Text('Filters', style: theme.textTheme.titleLarge),
                const Spacer(),
                if (widget.onClear != null)
                  TextButton(
                    onPressed: () {
                      if (widget.isCatalogMode) {
                        widget.onClear?.call();
                        Navigator.pop(context);
                      } else {
                        setState(() {
                          _localSelections.clear();
                        });
                      }
                    },
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Facet groups (scrollable if many)
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.facetGroups.map(_buildFacetGroup).toList(),
              ),
            ),
          ),

          // Apply button for library mode
          if (!widget.isCatalogMode && widget.onApply != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: () {
                  widget.onApply?.call(_localSelections);
                  Navigator.pop(context);
                },
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFacetGroup(CatalogFacetGroup group) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            group.name.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // Facet items
        ...group.facets.map((facet) => _buildFacetTile(facet, group)),
      ],
    );
  }

  Widget _buildFacetTile(CatalogFacet facet, CatalogFacetGroup group) {
    final bool isSelected;

    if (widget.isCatalogMode) {
      isSelected = facet.isActive;
    } else {
      // Library mode: check local selections
      final groupSelections = _localSelections[group.name] ?? {};
      isSelected = groupSelections.contains(facet.href);
    }

    return ListTile(
      leading: widget.isCatalogMode
          ? Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            )
          : Checkbox(
              value: isSelected,
              onChanged: (_) => _onFacetTap(facet, group),
            ),
      title: Text(facet.title),
      trailing: facet.count != null
          ? Text(
              '(${facet.count})',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      onTap: () => _onFacetTap(facet, group),
    );
  }

  void _onFacetTap(CatalogFacet facet, CatalogFacetGroup group) {
    if (widget.isCatalogMode) {
      // Immediate navigation for catalog mode
      widget.onFacetSelected(facet, group);
      Navigator.pop(context);
    } else {
      // Toggle selection for library mode
      setState(() {
        final groupSelections = _localSelections.putIfAbsent(
          group.name,
          () => {},
        );

        if (groupSelections.contains(facet.href)) {
          groupSelections.remove(facet.href);
          if (groupSelections.isEmpty) {
            _localSelections.remove(group.name);
          }
        } else {
          groupSelections.add(facet.href);
        }
      });
    }
  }
}

/// Helper function to show the facet selection sheet.
Future<void> showFacetSelectionSheet({
  required BuildContext context,
  required List<CatalogFacetGroup> facetGroups,
  required void Function(CatalogFacet facet, CatalogFacetGroup group)
  onFacetSelected,
  bool isCatalogMode = true,
  VoidCallback? onClear,
  Map<String, Set<String>>? selectedFacets,
  void Function(Map<String, Set<String>> selections)? onApply,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.7,
    ),
    builder: (context) => FacetSelectionSheet(
      facetGroups: facetGroups,
      onFacetSelected: onFacetSelected,
      isCatalogMode: isCatalogMode,
      onClear: onClear,
      selectedFacets: selectedFacets,
      onApply: onApply,
    ),
  );
}
