import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:fifty_ui/fifty_ui.dart';
import 'package:flutter/material.dart';

import '../../../../data/models/brief_model.dart';
import '../../../../shared/widgets/arena_card.dart';

/// Briefs panel for the Project Detail page.
///
/// Shows a status summary row with FiftyBadge pills and a compact
/// list of briefs with ID, title, priority badge, and status badge.
class ProjectBriefsPanel extends StatelessWidget {
  /// The list of briefs to display.
  final List<BriefModel> briefs;

  /// Status -> count mapping for the summary row.
  final Map<String, int> statusCounts;

  const ProjectBriefsPanel({
    super.key,
    required this.briefs,
    required this.statusCounts,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return ArenaCard(
      title: 'BRIEFS',
      trailing: Text(
        '${briefs.length}',
        style: textTheme.labelSmall!.copyWith(
          fontWeight: FiftyTypography.bold,
          color: colorScheme.onSurface,
        ),
      ),
      child: briefs.isEmpty
          ? Text(
              'No briefs for this project',
              style: textTheme.bodySmall!.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status summary row
                if (statusCounts.isNotEmpty) ...[
                  Wrap(
                    spacing: FiftySpacing.xs,
                    runSpacing: FiftySpacing.xs,
                    children: statusCounts.entries.map((entry) {
                      return FiftyBadge(
                        label: '${entry.key}: ${entry.value}',
                        variant: _variantForStatus(entry.key),
                        showGlow: false,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: FiftySpacing.sm),
                ],

                // Compact brief list (max 15)
                ...briefs.take(15).map((brief) => _BriefRow(brief: brief)),
              ],
            ),
    );
  }

  /// Map brief status strings to badge variants.
  FiftyBadgeVariant _variantForStatus(String status) {
    switch (status) {
      case 'Done':
        return FiftyBadgeVariant.success;
      case 'In Progress':
        return FiftyBadgeVariant.warning;
      case 'Blocked':
        return FiftyBadgeVariant.error;
      case 'Ready':
        return FiftyBadgeVariant.neutral;
      default:
        return FiftyBadgeVariant.neutral;
    }
  }
}

/// A single compact brief row.
class _BriefRow extends StatelessWidget {
  final BriefModel brief;

  const _BriefRow({required this.brief});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: FiftySpacing.xs),
      child: Row(
        children: [
          // Brief ID
          SizedBox(
            width: 72,
            child: Text(
              brief.briefId,
              style: textTheme.labelSmall!.copyWith(
                fontWeight: FiftyTypography.bold,
                color: colorScheme.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: FiftySpacing.xs),

          // Title
          Expanded(
            child: Text(
              brief.title,
              style: textTheme.labelSmall!.copyWith(
                fontWeight: FiftyTypography.medium,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: FiftySpacing.xs),

          // Priority badge
          FiftyBadge(
            label: brief.priority,
            variant: _priorityVariant(brief.priority),
            showGlow: false,
          ),
          const SizedBox(width: FiftySpacing.xs),

          // Status badge
          FiftyBadge(
            label: brief.status.toUpperCase(),
            variant: _statusVariant(brief.status),
            showGlow: false,
          ),
        ],
      ),
    );
  }

  FiftyBadgeVariant _priorityVariant(String priority) {
    switch (priority) {
      case 'P0':
        return FiftyBadgeVariant.error;
      case 'P1':
        return FiftyBadgeVariant.warning;
      case 'P2':
        return FiftyBadgeVariant.neutral;
      default:
        return FiftyBadgeVariant.neutral;
    }
  }

  FiftyBadgeVariant _statusVariant(String status) {
    switch (status) {
      case 'Done':
        return FiftyBadgeVariant.success;
      case 'In Progress':
        return FiftyBadgeVariant.warning;
      case 'Blocked':
        return FiftyBadgeVariant.error;
      case 'Ready':
        return FiftyBadgeVariant.neutral;
      default:
        return FiftyBadgeVariant.neutral;
    }
  }
}
