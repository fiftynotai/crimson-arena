import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:flutter/material.dart';

import '../../../../shared/utils/format_utils.dart';
import '../../../../shared/widgets/arena_card.dart';

/// Knowledge base panel for the Operations page.
///
/// Displays knowledge base statistics: total entries, categories,
/// and last updated timestamp.
class KnowledgePanel extends StatelessWidget {
  /// Raw knowledge state data from the API.
  final Map<String, dynamic>? data;

  const KnowledgePanel({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (data == null) {
      return ArenaCard(
        title: 'KNOWLEDGE BASE',
        child: Text(
          'Waiting for knowledge data...',
          style: textTheme.bodySmall!.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final totalEntries = data!['total_entries'] as int? ?? 0;
    final lastUpdated = data!['last_updated'] as String?;
    final categories = data!['categories'] as Map<String, dynamic>? ?? {};

    return ArenaCard(
      title: 'KNOWLEDGE BASE',
      trailing: Text(
        '${FormatUtils.formatNumber(totalEntries)} entries',
        style: textTheme.labelSmall!.copyWith(
          fontWeight: FiftyTypography.bold,
          color: colorScheme.onSurface,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Last updated
          _KnowledgeRow(
            label: 'LAST UPDATED',
            value: FormatUtils.timeAgo(lastUpdated),
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),

          // Category breakdown
          if (categories.isNotEmpty) ...[
            const SizedBox(height: FiftySpacing.sm),
            Text(
              'CATEGORIES',
              style: textTheme.labelSmall!.copyWith(
                fontWeight: FiftyTypography.medium,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
                letterSpacing: FiftyTypography.letterSpacingLabelMedium,
              ),
            ),
            const SizedBox(height: FiftySpacing.xs),
            ...categories.entries.map((entry) {
              final count = entry.value is int ? entry.value as int : 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: _KnowledgeRow(
                  label: entry.key.toUpperCase(),
                  value: FormatUtils.formatNumber(count),
                  textTheme: textTheme,
                  colorScheme: colorScheme,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

/// A single metric row for knowledge data.
class _KnowledgeRow extends StatelessWidget {
  final String label;
  final String value;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  const _KnowledgeRow({
    required this.label,
    required this.value,
    required this.textTheme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.labelSmall!.copyWith(
            fontWeight: FiftyTypography.medium,
            color: colorScheme.onSurface.withValues(alpha: 0.4),
            letterSpacing: FiftyTypography.letterSpacingLabelMedium,
          ),
        ),
        Text(
          value,
          style: textTheme.labelSmall!.copyWith(
            fontWeight: FiftyTypography.bold,
            color: colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
