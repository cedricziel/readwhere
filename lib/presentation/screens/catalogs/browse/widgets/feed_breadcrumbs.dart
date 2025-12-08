import 'package:flutter/material.dart';

/// Breadcrumb navigation widget for OPDS feed navigation
class FeedBreadcrumbs extends StatelessWidget {
  final List<String> breadcrumbs;
  final Function(int) onTap;

  const FeedBreadcrumbs({
    super.key,
    required this.breadcrumbs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (breadcrumbs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: breadcrumbs.length,
        separatorBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            Icons.chevron_right,
            size: 20,
            color: theme.colorScheme.outline,
          ),
        ),
        itemBuilder: (context, index) {
          final isLast = index == breadcrumbs.length - 1;
          final crumb = breadcrumbs[index];

          return Center(
            child: InkWell(
              onTap: isLast ? null : () => onTap(index),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  crumb,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isLast
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.primary,
                    fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
