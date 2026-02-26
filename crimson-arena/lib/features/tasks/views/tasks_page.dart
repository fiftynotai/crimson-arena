import 'package:crimson_arena/core/constants/arena_breakpoints.dart';
import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:fifty_ui/fifty_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../services/project_selector_service.dart';
import '../../../shared/widgets/arena_hover_button.dart';
import '../../../shared/widgets/arena_scaffold.dart';
import '../controllers/tasks_view_model.dart';
import 'widgets/agent_workload_bar.dart';
import 'widgets/task_column.dart';

/// Tasks page -- kanban board for the brain task queue.
///
/// Displays tasks grouped by status (pending, active, blocked, done,
/// cancelled, failed) in horizontally scrollable columns. Includes
/// filter chips, an agent workload bar, and a refresh button.
class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ArenaScaffold(
      title: 'TASKS',
      activeTabIndex: 3,
      body: GetX<TasksViewModel>(
        builder: (controller) {
          if (controller.isLoading.value) {
            return const Center(
              child: FiftyLoadingIndicator(
                style: FiftyLoadingStyle.sequence,
                size: FiftyLoadingSize.large,
                sequences: [
                  '> SCANNING TASK QUEUE...',
                  '> LOADING WORKERS...',
                  '> READY.',
                ],
              ),
            );
          }

          return _buildKanban(context, controller);
        },
      ),
    );
  }

  Widget _buildKanban(BuildContext context, TasksViewModel vm) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < ArenaBreakpoints.narrow;
        final hPad = isNarrow ? FiftySpacing.sm : FiftySpacing.lg;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header row
            _buildHeader(context, vm, hPad),

            // Filter chips
            Obx(() {
              final hasFilters = vm.selectedProject.value != null ||
                  vm.selectedAssignee.value != null;
              if (!hasFilters &&
                  vm.availableProjects.isEmpty &&
                  vm.availableAssignees.isEmpty) {
                return const SizedBox.shrink();
              }
              return _buildFilters(context, vm, hPad);
            }),

            // Agent workload bar
            Obx(() {
              final workload = Map<String, int>.from(vm.agentWorkload);
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: AgentWorkloadBar(workload: workload),
              );
            }),
            const SizedBox(height: FiftySpacing.sm),

            // Kanban columns
            Expanded(
              child: Obx(() {
                if (vm.totalCount == 0) {
                  return _buildEmptyState(context);
                }

                return LayoutBuilder(
                  builder: (context, kanbanConstraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      physics: const ClampingScrollPhysics(),
                      child: SizedBox(
                        // Use the kanban area height, not the outer
                        // LayoutBuilder constraints.
                        height: kanbanConstraints.maxHeight,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TaskColumn(
                              status: 'pending',
                              tasks: vm.pendingTasks,
                            ),
                            TaskColumn(
                              status: 'active',
                              tasks: vm.activeTasks,
                            ),
                            TaskColumn(
                              status: 'blocked',
                              tasks: vm.blockedTasks,
                            ),
                            TaskColumn(
                              status: 'done',
                              tasks: vm.doneTasks,
                            ),
                            if (vm.cancelledTasks.isNotEmpty)
                              TaskColumn(
                                status: 'cancelled',
                                tasks: vm.cancelledTasks,
                              ),
                            if (vm.failedTasks.isNotEmpty)
                              TaskColumn(
                                status: 'failed',
                                tasks: vm.failedTasks,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    TasksViewModel vm,
    double hPad,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: hPad,
        vertical: FiftySpacing.sm,
      ),
      child: FiftySectionHeader(
        title: 'TASK QUEUE',
        size: FiftySectionHeaderSize.small,
        showDivider: false,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Total count badge
            Obx(() {
              return FiftyBadge(
                label: '${vm.totalCount} tasks',
                customColor: colorScheme.primary,
                showGlow: false,
              );
            }),
            const SizedBox(width: FiftySpacing.sm),

            // Refresh button
            ArenaHoverButton(
              onTap: vm.refreshData,
              child: Text(
                'REFRESH',
                style: textTheme.labelSmall!.copyWith(
                  fontWeight: FiftyTypography.bold,
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: FiftyTypography.letterSpacingLabelMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(
    BuildContext context,
    TasksViewModel vm,
    double hPad,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // When a global project is selected, local project chips are redundant.
    final globalProjectSelected =
        Get.find<ProjectSelectorService>().selectedProjectSlug.value != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, FiftySpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Project filter chips (hidden when global project is selected).
            if (!globalProjectSelected)
              ...vm.availableProjects.map((project) {
                final isSelected = vm.selectedProject.value == project;
                return Padding(
                  padding: const EdgeInsets.only(right: FiftySpacing.xs),
                  child: FiftyChip(
                    label: project.toUpperCase(),
                    selected: isSelected,
                    onTap: () => vm.filterByProject(
                      isSelected ? null : project,
                    ),
                  ),
                );
              }),

            if (!globalProjectSelected &&
                vm.availableProjects.isNotEmpty &&
                vm.availableAssignees.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: FiftySpacing.xs),
                child: Text(
                  '|',
                  style: textTheme.bodySmall!.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                ),
              ),

            // Assignee filter chips (always visible).
            ...vm.availableAssignees.map((assignee) {
              final isSelected = vm.selectedAssignee.value == assignee;
              return Padding(
                padding: const EdgeInsets.only(right: FiftySpacing.xs),
                child: FiftyChip(
                  label: assignee.toUpperCase(),
                  selected: isSelected,
                  onTap: () => vm.filterByAssignee(
                    isSelected ? null : assignee,
                  ),
                ),
              );
            }),

            // Clear all filters
            if (vm.selectedProject.value != null ||
                vm.selectedAssignee.value != null)
              ArenaHoverButton(
                onTap: vm.clearFilters,
                child: Text(
                  'CLEAR',
                  style: textTheme.labelSmall!.copyWith(
                    fontWeight: FiftyTypography.bold,
                    color: colorScheme.primary,
                    letterSpacing: FiftyTypography.letterSpacingLabelMedium,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Center(
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
            '> Brain tasks will appear here when workers are active.',
            style: textTheme.bodyMedium!.copyWith(
              fontWeight: FiftyTypography.medium,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
