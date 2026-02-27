import 'package:fifty_theme/fifty_theme.dart';
import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:fifty_ui/fifty_ui.dart';
import 'package:flutter/material.dart';

import '../../../../shared/utils/format_utils.dart';
import '../../../../shared/widgets/arena_card.dart';

/// Brain health panel for the Operations page.
///
/// Displays brain infrastructure health: DB status, uptime, memory usage,
/// database size, and learning count. All map access is null-safe.
class BrainHealthPanel extends StatelessWidget {
  /// Raw brain health data from the API.
  final Map<String, dynamic>? data;

  const BrainHealthPanel({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ext = theme.extension<FiftyThemeExtension>()!;
    final textTheme = theme.textTheme;

    if (data == null) {
      return ArenaCard(
        title: 'BRAIN HEALTH',
        child: Text(
          'Waiting for brain health data...',
          style: textTheme.bodySmall!.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final status = data!['status'] as String? ?? 'unknown';
    final isHealthy = status == 'healthy' || status == 'ok';
    final uptimeSeconds = data!['uptime_seconds'] as int? ?? 0;
    final memoryBytes = data!['memory_bytes'] as int? ?? 0;
    final dbSizeBytes = data!['db_size_bytes'] as int? ?? 0;
    final learnings = data!['learnings'] as int? ?? 0;
    final version = data!['version'] as String?;

    return ArenaCard(
      title: 'BRAIN HEALTH',
      trailing: FiftyBadge(
        label: status.toUpperCase(),
        variant:
            isHealthy ? FiftyBadgeVariant.success : FiftyBadgeVariant.error,
        showGlow: isHealthy,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricRow(
            label: 'UPTIME',
            value: FormatUtils.formatUptime(uptimeSeconds),
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: FiftySpacing.xs),
          _MetricRow(
            label: 'MEMORY',
            value: memoryBytes > 0
                ? FormatUtils.formatBytes(memoryBytes)
                : '--',
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: FiftySpacing.xs),
          _MetricRow(
            label: 'DB SIZE',
            value: dbSizeBytes > 0
                ? FormatUtils.formatBytes(dbSizeBytes)
                : '--',
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: FiftySpacing.xs),
          _MetricRow(
            label: 'LEARNINGS',
            value: FormatUtils.formatNumber(learnings),
            textTheme: textTheme,
            colorScheme: colorScheme,
            valueColor: ext.success,
          ),
          if (version != null) ...[
            const SizedBox(height: FiftySpacing.xs),
            _MetricRow(
              label: 'VERSION',
              value: version,
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),
          ],
        ],
      ),
    );
  }
}

/// A single metric row with label + value.
class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final TextTheme textTheme;
  final ColorScheme colorScheme;
  final Color? valueColor;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.textTheme,
    required this.colorScheme,
    this.valueColor,
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
            color: valueColor ??
                colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
