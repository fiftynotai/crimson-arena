import 'package:crimson_arena/core/constants/arena_colors.dart';
import 'package:crimson_arena/core/constants/arena_sizes.dart';
import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:fifty_ui/fifty_ui.dart';
import 'package:flutter/material.dart';

import '../../../../data/models/task_model.dart';
import 'task_card.dart';

/// A single kanban column in the task board.
///
/// Displays a status header with a count badge, followed by a scrollable
/// list of [TaskCard] widgets. Uses a flat background so task cards
/// float independently without a card-on-card effect. A vertical divider
/// separates each column.
class TaskColumn extends StatelessWidget {
  /// Status key used for color lookup and display.
  final String status;

  /// Tasks to display in this column.
  final List<TaskModel> tasks;

  /// Fixed column width. Defaults to 280.
  final double width;

  const TaskColumn({
    super.key,
    required this.status,
    required this.tasks,
    this.width = 280,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final statusColor = ArenaColors.taskStatusColor(status);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Column content
          SizedBox(
            width: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Column header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FiftySpacing.sm,
                    vertical: FiftySpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: ArenaSizes.statusDotLarge,
                        height: ArenaSizes.statusDotLarge,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: FiftySpacing.xs),
                      Text(
                        status.toUpperCase(),
                        style: textTheme.labelSmall!.copyWith(
                          fontWeight: FiftyTypography.bold,
                          color: colorScheme.onSurface,
                          letterSpacing: FiftyTypography.letterSpacingLabel,
                        ),
                      ),
                      const Spacer(),
                      FiftyBadge(
                        label: '${tasks.length}',
                        customColor: statusColor,
                        showGlow: false,
                      ),
                    ],
                  ),
                ),

                // Task list or empty state
                Expanded(
                  child: tasks.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.builder(
                          padding: const EdgeInsets.all(FiftySpacing.xs),
                          physics: const ClampingScrollPhysics(),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) =>
                              TaskCard(task: tasks[index]),
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(width: FiftySpacing.sm),

          // Vertical divider
          Container(
            width: 1,
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),

          const SizedBox(width: FiftySpacing.sm),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Text(
        'No tasks',
        style: textTheme.bodySmall!.copyWith(
          fontWeight: FiftyTypography.medium,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
