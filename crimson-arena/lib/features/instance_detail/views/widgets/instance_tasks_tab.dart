import 'package:crimson_arena/core/theme/arena_text_styles.dart';
import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:fifty_ui/fifty_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/agent_constants.dart';
import '../../../../core/constants/arena_colors.dart';
import '../../../../data/models/task_model.dart';
import '../../../../shared/utils/format_utils.dart';
import '../../controllers/instance_detail_view_model.dart';

/// Tasks tab for the Instance Detail page.
///
/// Displays tasks filtered by the instance's project slug. If the
/// instance has a `currentBrief`, tasks matching that brief ID are
/// highlighted with a primary-tinted accent.
class InstanceTasksTab extends StatelessWidget {
  final InstanceDetailViewModel vm;

  const InstanceTasksTab({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tasks = vm.instanceTasks.toList();
      final instance = vm.instance.value;
      final currentBrief = instance?.currentBrief;

      if (tasks.isEmpty) {
        return _buildEmptyState(context);
      }

      // Build status summary.
      final statusCounts = <String, int>{};
      for (final task in tasks) {
        statusCounts[task.status] = (statusCounts[task.status] ?? 0) + 1;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status summary
          Padding(
            padding: const EdgeInsets.symmetric(vertical: FiftySpacing.sm),
            child: _buildStatusSummary(context, statusCounts, tasks.length),
          ),

          // Task list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: FiftySpacing.md),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                final isHighlighted = currentBrief != null &&
                    currentBrief.isNotEmpty &&
                    task.briefId == currentBrief;
                return _TaskRow(
                  task: task,
                  isHighlighted: isHighlighted,
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildStatusSummary(
    BuildContext context,
    Map<String, int> statusCounts,
    int total,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Row(
      children: [
        Text(
          'TASKS',
          style: textTheme.labelMedium!.copyWith(
            color: colorScheme.onSurfaceVariant,
            letterSpacing: FiftyTypography.letterSpacingLabelMedium,
          ),
        ),
        const SizedBox(width: FiftySpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: FiftySpacing.sm,
            vertical: FiftySpacing.xs,
          ),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.15),
            borderRadius: FiftyRadii.smRadius,
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            '$total total',
            style: ArenaTextStyles.mono(
              context,
              fontSize: FiftyTypography.labelSmall,
              fontWeight: FiftyTypography.semiBold,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
        const SizedBox(width: FiftySpacing.sm),
        Expanded(
          child: Wrap(
            spacing: FiftySpacing.xs,
            runSpacing: FiftySpacing.xs,
            children: statusCounts.entries.map((entry) {
              return FiftyBadge(
                label: '${entry.key.toUpperCase()}: ${entry.value}',
                customColor: ArenaColors.taskStatusColor(entry.key),
                showGlow: false,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: FiftySpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'NO TASKS',
              style: textTheme.titleLarge!.copyWith(
                fontWeight: FiftyTypography.extraBold,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                letterSpacing: FiftyTypography.letterSpacingLabelMedium,
              ),
            ),
            const SizedBox(height: FiftySpacing.sm),
            Text(
              '> No tasks found for this instance\'s project.',
              style: textTheme.bodyMedium!.copyWith(
                fontWeight: FiftyTypography.medium,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single task row with status color and optional brief highlight.
class _TaskRow extends StatelessWidget {
  final TaskModel task;
  final bool isHighlighted;

  const _TaskRow({
    required this.task,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final statusColor = ArenaColors.taskStatusColor(task.status);
    final priorityColor = ArenaColors.taskPriorityColor(task.priority);

    return Padding(
      padding: const EdgeInsets.only(bottom: FiftySpacing.xs),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: FiftyRadii.smRadius,
          border: Border(
            left: BorderSide(
              color: isHighlighted ? colorScheme.primary : statusColor,
              width: isHighlighted ? 3 : 2,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: FiftySpacing.sm,
          vertical: FiftySpacing.xs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Priority indicator
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: priorityColor,
              ),
            ),
            const SizedBox(width: FiftySpacing.xs),

            // Title + brief/type
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: textTheme.labelSmall!.copyWith(
                      fontWeight: FiftyTypography.semiBold,
                      color: isHighlighted
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withValues(alpha: 0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (task.briefId != null &&
                          task.briefId!.isNotEmpty) ...[
                        Text(
                          task.briefId!,
                          style: ArenaTextStyles.mono(
                            context,
                            fontSize: 10,
                            fontWeight: FiftyTypography.medium,
                            color: isHighlighted
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: FiftySpacing.xs),
                      ],
                      Text(
                        task.taskType.toUpperCase(),
                        style: textTheme.labelSmall!.copyWith(
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.5),
                          letterSpacing:
                              FiftyTypography.letterSpacingLabel,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Assignee
            if (task.assignee != null && task.assignee!.isNotEmpty) ...[
              const SizedBox(width: FiftySpacing.sm),
              Text(
                task.assignee!.toUpperCase(),
                style: ArenaTextStyles.mono(
                  context,
                  fontSize: 10,
                  fontWeight: FiftyTypography.bold,
                  color: Color(
                    AgentConstants.agentColors[task.assignee] ?? 0xFF888888,
                  ),
                ),
              ),
            ],

            // Status badge
            const SizedBox(width: FiftySpacing.sm),
            FiftyBadge(
              label: task.status.toUpperCase(),
              customColor: statusColor,
              showGlow: false,
            ),

            // Timestamp
            const SizedBox(width: FiftySpacing.sm),
            Text(
              FormatUtils.timeAgo(task.updatedAt),
              style: ArenaTextStyles.mono(
                context,
                fontSize: 10,
                fontWeight: FiftyTypography.medium,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
