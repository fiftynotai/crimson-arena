import 'package:crimson_arena/core/constants/arena_colors.dart';
import 'package:crimson_arena/core/constants/arena_sizes.dart';
import 'package:crimson_arena/core/theme/arena_text_styles.dart';
import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:flutter/material.dart';

import '../../../../data/models/task_model.dart';
import 'task_card.dart';

/// A single kanban column in the task board.
///
/// Displays a status header with a count badge, followed by a scrollable
/// list of [TaskCard] widgets. Each column has a fixed width and a
/// status-colored accent in the header.
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

    return Container(
      width: width,
      margin: const EdgeInsets.only(right: FiftySpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: FiftyRadii.mdRadius,
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Column header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: FiftySpacing.sm,
              vertical: FiftySpacing.sm,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Status color dot
                Container(
                  width: ArenaSizes.statusDotLarge,
                  height: ArenaSizes.statusDotLarge,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: FiftySpacing.xs),

                // Status label
                Text(
                  status.toUpperCase(),
                  style: textTheme.labelSmall!.copyWith(
                    fontWeight: FiftyTypography.bold,
                    color: colorScheme.onSurface,
                    letterSpacing: FiftyTypography.letterSpacingLabel,
                  ),
                ),
                const Spacer(),

                // Count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FiftySpacing.xs,
                    vertical: ArenaSizes.badgeVerticalPadding,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: FiftyRadii.smRadius,
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: ArenaTextStyles.mono(
                      context,
                      fontSize: ArenaSizes.monoFontSizeMicro,
                      fontWeight: FiftyTypography.bold,
                      color: statusColor,
                    ),
                  ),
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
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

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
