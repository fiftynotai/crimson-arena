import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:fifty_ui/fifty_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/arena_colors.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/arena_card.dart';
import '../../controllers/home_view_model.dart';

/// Summary card showing task status counts (pending, active, blocked, done).
///
/// Displays compact status pills similar to the briefs panel. Tapping the
/// card navigates to the Tasks page for the full kanban board.
class TasksSummaryCard extends StatelessWidget {
  const TasksSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Get.find<HomeViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Obx(() {
      final tasks = vm.recentTasks;

      // Count by status.
      final counts = <String, int>{};
      for (final task in tasks) {
        counts[task.status] = (counts[task.status] ?? 0) + 1;
      }

      return ArenaCard(
        title: 'TASKS',
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 12,
          color: colorScheme.onSurfaceVariant,
        ),
        onTap: () => Get.toNamed(AppRoutes.tasks),
        child: tasks.isEmpty
            ? Text(
                'No tasks in queue',
                style: textTheme.bodySmall!.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            : Wrap(
                spacing: FiftySpacing.xs,
                runSpacing: FiftySpacing.xs,
                children: counts.entries.map((entry) {
                  return FiftyBadge(
                    label: '${_capitalize(entry.key)}: ${entry.value}',
                    customColor: ArenaColors.taskStatusColor(entry.key),
                    showGlow: false,
                  );
                }).toList(),
              ),
      );
    });
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
