import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:fifty_ui/fifty_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/arena_breakpoints.dart';
import '../../../shared/widgets/arena_scaffold.dart';
import '../controllers/project_detail_view_model.dart';
import 'widgets/project_briefs_panel.dart';
import 'widgets/project_events_panel.dart';
import 'widgets/project_header_card.dart';
import 'widgets/project_instances_panel.dart';
import 'widgets/project_tasks_panel.dart';

/// Project Detail page -- scoped dashboard for a single project.
///
/// Displays project metadata, instances, briefs, tasks, and recent events
/// all filtered to the project identified by the `:slug` route parameter.
///
/// Layout:
/// - Wide (>900px): two columns side by side
/// - Narrow (<900px): single column stacked
class ProjectDetailPage extends StatefulWidget {
  const ProjectDetailPage({super.key});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  @override
  void initState() {
    super.initState();
    final slug = Get.parameters['slug'] ?? '';
    if (slug.isNotEmpty) {
      Get.find<ProjectDetailViewModel>().loadProject(slug);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final slug = Get.parameters['slug'] ?? '';

    return ArenaScaffold(
      title: 'PROJECT',
      activeTabIndex: -1,
      body: slug.isEmpty
          ? Center(
              child: Text(
                'No project slug provided.',
                style: textTheme.bodyMedium!.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : GetX<ProjectDetailViewModel>(
              builder: (vm) {
                if (vm.isLoading.value) {
                  return const Center(
                    child: FiftyLoadingIndicator(
                      style: FiftyLoadingStyle.sequence,
                      size: FiftyLoadingSize.large,
                      sequences: [
                        '> LOADING PROJECT DATA...',
                        '> FETCHING INSTANCES...',
                        '> SCANNING BRIEFS...',
                        '> READY.',
                      ],
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide =
                        constraints.maxWidth > ArenaBreakpoints.wide;
                    final isNarrow =
                        constraints.maxWidth < ArenaBreakpoints.narrow;
                    final pagePad =
                        isNarrow ? FiftySpacing.sm : FiftySpacing.md;

                    return SingleChildScrollView(
                      padding: EdgeInsets.all(pagePad),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Back navigation row
                          _buildBackRow(colorScheme, textTheme),
                          const SizedBox(height: FiftySpacing.sm),
                          // Main content
                          if (isWide)
                            _buildWideLayout(vm)
                          else
                            _buildNarrowLayout(vm),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  /// Back navigation row with icon and label.
  Widget _buildBackRow(ColorScheme colorScheme, TextTheme textTheme) {
    return InkWell(
      onTap: () => Get.back(),
      borderRadius: FiftyRadii.smRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FiftySpacing.xs,
          vertical: FiftySpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.arrow_back,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: FiftySpacing.xs),
            Text(
              'Back',
              style: textTheme.labelMedium!.copyWith(
                color: colorScheme.onSurfaceVariant,
                letterSpacing: FiftyTypography.letterSpacingLabelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Wide layout: two columns -- left: header + instances, right: briefs + tasks + events.
  Widget _buildWideLayout(ProjectDetailViewModel vm) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column
        Expanded(
          child: Column(
            children: [
              Obx(() => ProjectHeaderCard(project: vm.project.value)),
              const SizedBox(height: FiftySpacing.sm),
              Obx(() => ProjectInstancesPanel(instances: vm.instances)),
            ],
          ),
        ),
        const SizedBox(width: FiftySpacing.sm),
        // Right column
        Expanded(
          child: Column(
            children: [
              Obx(() => ProjectBriefsPanel(
                    briefs: vm.briefs,
                    statusCounts: vm.briefStatusCounts,
                  )),
              const SizedBox(height: FiftySpacing.sm),
              Obx(() => ProjectTasksPanel(
                    tasks: vm.tasks,
                    statusCounts: vm.taskStatusCounts,
                    agentWorkload: vm.taskAgentWorkload,
                  )),
              const SizedBox(height: FiftySpacing.sm),
              Obx(() => ProjectEventsPanel(events: vm.recentEvents)),
            ],
          ),
        ),
      ],
    );
  }

  /// Narrow layout: single column stacked.
  Widget _buildNarrowLayout(ProjectDetailViewModel vm) {
    return Column(
      children: [
        Obx(() => ProjectHeaderCard(project: vm.project.value)),
        const SizedBox(height: FiftySpacing.sm),
        Obx(() => ProjectInstancesPanel(instances: vm.instances)),
        const SizedBox(height: FiftySpacing.sm),
        Obx(() => ProjectBriefsPanel(
              briefs: vm.briefs,
              statusCounts: vm.briefStatusCounts,
            )),
        const SizedBox(height: FiftySpacing.sm),
        Obx(() => ProjectTasksPanel(
              tasks: vm.tasks,
              statusCounts: vm.taskStatusCounts,
              agentWorkload: vm.taskAgentWorkload,
            )),
        const SizedBox(height: FiftySpacing.sm),
        Obx(() => ProjectEventsPanel(events: vm.recentEvents)),
        const SizedBox(height: FiftySpacing.xxl),
      ],
    );
  }
}
