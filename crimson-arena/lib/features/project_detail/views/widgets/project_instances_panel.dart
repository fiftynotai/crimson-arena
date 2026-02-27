import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:fifty_ui/fifty_ui.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/arena_text_styles.dart';
import '../../../../data/models/instance_model.dart';
import '../../../../shared/utils/format_utils.dart';
import '../../../../shared/widgets/arena_card.dart';

/// Instances panel for the Project Detail page.
///
/// Displays a compact list of instances belonging to the project,
/// showing instance ID (truncated), status badge, current brief,
/// and last heartbeat.
class ProjectInstancesPanel extends StatelessWidget {
  /// The list of instances to display.
  final List<InstanceModel> instances;

  const ProjectInstancesPanel({super.key, required this.instances});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return ArenaCard(
      title: 'INSTANCES',
      trailing: Text(
        '${instances.length}',
        style: textTheme.labelSmall!.copyWith(
          fontWeight: FiftyTypography.bold,
          color: colorScheme.onSurface,
        ),
      ),
      child: instances.isEmpty
          ? Text(
              'No instances for this project',
              style: textTheme.bodySmall!.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: instances.map((instance) {
                return _InstanceRow(instance: instance);
              }).toList(),
            ),
    );
  }
}

/// A single compact instance row.
class _InstanceRow extends StatelessWidget {
  final InstanceModel instance;

  const _InstanceRow({required this.instance});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final isActive = instance.isActive;
    final truncatedId = instance.id.length > 8
        ? '${instance.id.substring(0, 8)}...'
        : instance.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: FiftySpacing.xs),
      child: Row(
        children: [
          // Instance ID (truncated, mono)
          Tooltip(
            message: instance.id,
            child: Text(
              truncatedId,
              style: ArenaTextStyles.mono(
                context,
                fontSize: 11,
                fontWeight: FiftyTypography.medium,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(width: FiftySpacing.sm),

          // Status badge
          FiftyBadge(
            label: instance.status.toUpperCase(),
            variant: isActive
                ? FiftyBadgeVariant.success
                : FiftyBadgeVariant.neutral,
            showGlow: isActive,
          ),
          const SizedBox(width: FiftySpacing.sm),

          // Current brief (if any)
          if (instance.hasBrief) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: FiftyRadii.smRadius,
              ),
              child: Text(
                instance.currentBrief!,
                style: textTheme.labelSmall!.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: FiftySpacing.sm),
          ],

          const Spacer(),

          // Last heartbeat
          Text(
            FormatUtils.timeAgo(instance.lastHeartbeat),
            style: ArenaTextStyles.mono(
              context,
              fontSize: 10,
              fontWeight: FiftyTypography.medium,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
