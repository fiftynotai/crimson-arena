import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:fifty_ui/fifty_ui.dart';
import 'package:flutter/material.dart';

import '../../../../shared/utils/format_utils.dart';
import '../../../../shared/widgets/arena_card.dart';

/// Sync status panel for the Operations page.
///
/// Displays the brain sync pipeline status: last push/pull timestamps,
/// queue depth, and online/offline state.
class SyncStatusPanel extends StatelessWidget {
  /// Raw sync status data from the API.
  final Map<String, dynamic>? data;

  const SyncStatusPanel({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (data == null) {
      return ArenaCard(
        title: 'SYNC STATUS',
        child: Text(
          'Waiting for sync status data...',
          style: textTheme.bodySmall!.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final isOnline = data!['online'] as bool? ?? false;
    final lastPush = data!['last_push'] as String?;
    final lastPull = data!['last_pull'] as String?;
    final queueDepth = data!['queue_depth'] as int? ?? 0;
    final mode = data!['mode'] as String? ?? 'unknown';

    return ArenaCard(
      title: 'SYNC STATUS',
      trailing: FiftyBadge(
        label: isOnline ? 'ONLINE' : 'OFFLINE',
        variant: isOnline
            ? FiftyBadgeVariant.success
            : FiftyBadgeVariant.error,
        showGlow: isOnline,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SyncMetricRow(
            label: 'MODE',
            value: mode.toUpperCase(),
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: FiftySpacing.xs),
          _SyncMetricRow(
            label: 'LAST PUSH',
            value: FormatUtils.timeAgo(lastPush),
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: FiftySpacing.xs),
          _SyncMetricRow(
            label: 'LAST PULL',
            value: FormatUtils.timeAgo(lastPull),
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: FiftySpacing.xs),
          _SyncMetricRow(
            label: 'QUEUE',
            value: '$queueDepth pending',
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }
}

/// A single metric row for sync status.
class _SyncMetricRow extends StatelessWidget {
  final String label;
  final String value;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  const _SyncMetricRow({
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
