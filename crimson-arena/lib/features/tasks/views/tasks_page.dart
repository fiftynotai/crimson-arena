import 'package:crimson_arena/core/constants/arena_breakpoints.dart';
import 'package:crimson_arena/core/theme/arena_text_styles.dart';
import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:fifty_ui/fifty_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: AgentWorkloadBar(workload: vm.agentWorkload),
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
      child: Row(
        children: [
          Text(
            'TASK QUEUE',
            style: textTheme.titleSmall!.copyWith(
              fontWeight: FiftyTypography.extraBold,
              color: colorScheme.onSurface,
              letterSpacing: FiftyTypography.letterSpacingLabelMedium,
            ),
          ),
          const SizedBox(width: FiftySpacing.sm),

          // Total count badge
          Obx(() {
            return Container(
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
                '${vm.totalCount} tasks',
                style: ArenaTextStyles.mono(
                  context,
                  fontSize: FiftyTypography.labelSmall,
                  fontWeight: FiftyTypography.semiBold,
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            );
          }),

          const Spacer(),

          // Refresh button
          _HoverButton(
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

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, FiftySpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Project filter chips
            ...vm.availableProjects.map((project) {
              final isSelected = vm.selectedProject.value == project;
              return Padding(
                padding: const EdgeInsets.only(right: FiftySpacing.xs),
                child: _FilterChip(
                  label: project.toUpperCase(),
                  isSelected: isSelected,
                  onTap: () => vm.filterByProject(
                    isSelected ? null : project,
                  ),
                ),
              );
            }),

            if (vm.availableProjects.isNotEmpty &&
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

            // Assignee filter chips
            ...vm.availableAssignees.map((assignee) {
              final isSelected = vm.selectedAssignee.value == assignee;
              return Padding(
                padding: const EdgeInsets.only(right: FiftySpacing.xs),
                child: _FilterChip(
                  label: assignee.toUpperCase(),
                  isSelected: isSelected,
                  onTap: () => vm.filterByAssignee(
                    isSelected ? null : assignee,
                  ),
                ),
              );
            }),

            // Clear all filters
            if (vm.selectedProject.value != null ||
                vm.selectedAssignee.value != null)
              _HoverButton(
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

/// A selectable filter chip.
class _FilterChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: FiftySpacing.sm,
            vertical: FiftySpacing.xs,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? colorScheme.primary.withValues(alpha: 0.2)
                : _hovered
                    ? colorScheme.onSurface.withValues(alpha: 0.08)
                    : Colors.transparent,
            borderRadius: FiftyRadii.smRadius,
            border: Border.all(
              color: widget.isSelected
                  ? colorScheme.primary.withValues(alpha: 0.5)
                  : _hovered
                      ? colorScheme.outline
                      : colorScheme.outline.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Text(
            widget.label,
            style: textTheme.labelSmall!.copyWith(
              fontWeight: widget.isSelected
                  ? FiftyTypography.bold
                  : FiftyTypography.medium,
              color: widget.isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              letterSpacing: FiftyTypography.letterSpacingLabel,
            ),
          ),
        ),
      ),
    );
  }
}

/// A button with hover feedback: background tint appears on mouse hover.
class _HoverButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;

  const _HoverButton({this.onTap, required this.child});

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: FiftySpacing.sm,
            vertical: FiftySpacing.xs,
          ),
          decoration: BoxDecoration(
            color: _hovered
                ? colorScheme.onSurface.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: FiftyRadii.smRadius,
            border: Border.all(
              color: _hovered ? colorScheme.outline : Colors.transparent,
              width: 1,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
