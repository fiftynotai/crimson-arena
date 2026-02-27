import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:fifty_ui/fifty_ui.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/arena_colors.dart';
import '../../../../data/models/task_model.dart';
import '../../../../shared/widgets/arena_card.dart';

/// Tasks panel for the Project Detail page.
///
/// Displays a status summary row with badge pills, an agent workload
/// section, and empty state handling.
class ProjectTasksPanel extends StatelessWidget {
  /// The list of tasks to display.
  final List<TaskModel> tasks;

  /// Status -> count mapping for the summary row.
  final Map<String, int> statusCounts;

  /// Assignee -> active task count for the workload section.
  final Map<String, int> agentWorkload;

  const ProjectTasksPanel({
    super.key,
    required this.tasks,
    required this.statusCounts,
    required this.agentWorkload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return ArenaCard(
      title: 'TASK QUEUE',
      trailing: Text(
        '${tasks.length}',
        style: textTheme.labelSmall!.copyWith(
          fontWeight: FiftyTypography.bold,
          color: colorScheme.onSurface,
        ),
      ),
      child: tasks.isEmpty
          ? Text(
              'No tasks for this project',
              style: textTheme.bodySmall!.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status summary badges
                if (statusCounts.isNotEmpty) ...[
                  Wrap(
                    spacing: FiftySpacing.xs,
                    runSpacing: FiftySpacing.xs,
                    children: statusCounts.entries.map((entry) {
                      return FiftyBadge(
                        label:
                            '${entry.key.toUpperCase()}: ${entry.value}',
                        customColor:
                            ArenaColors.taskStatusColor(entry.key),
                        showGlow: false,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: FiftySpacing.sm),
                ],

                // Agent workload section
                if (agentWorkload.isNotEmpty) ...[
                  Text(
                    'AGENT WORKLOAD',
                    style: textTheme.labelSmall!.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing:
                          FiftyTypography.letterSpacingLabelMedium,
                    ),
                  ),
                  const SizedBox(height: FiftySpacing.xs),
                  ...agentWorkload.entries.map((entry) {
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: FiftySpacing.xs),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 12,
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: FiftySpacing.xs),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: textTheme.labelSmall!.copyWith(
                                fontWeight: FiftyTypography.medium,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: FiftySpacing.sm),
                          FiftyBadge(
                            label: '${entry.value}',
                            variant: FiftyBadgeVariant.neutral,
                            showGlow: false,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
    );
  }
}
