import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:fifty_ui/fifty_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/arena_breakpoints.dart';
import '../../../data/models/brain_event_model.dart';
import '../../../data/models/brief_model.dart';
import '../../../data/models/instance_model.dart';
import '../../../data/models/project_budget_model.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/task_model.dart';
import '../../../core/routing/app_routes.dart';
import '../../../shared/widgets/arena_breadcrumb.dart';
import '../../../shared/widgets/arena_scaffold.dart';
import '../controllers/project_detail_view_model.dart';
import 'widgets/project_briefs_panel.dart';
import 'widgets/project_budget_card.dart';
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
      breadcrumbs: [
        BreadcrumbSegment(label: 'HOME', route: AppRoutes.home),
        BreadcrumbSegment(label: 'OPERATIONS', route: AppRoutes.operations),
        BreadcrumbSegment(label: slug),
      ],
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

                // Read all reactive values here so GetX tracks them.
                final project = vm.project.value;
                final instances = vm.instances.toList();
                final briefs = vm.briefs.toList();
                final events = vm.recentEvents.toList();
                final tasks = vm.tasks.toList();
                final budgetData = vm.budget.value;
                final briefCounts = vm.briefStatusCounts;
                final taskCounts = vm.taskStatusCounts;
                final agentWork = vm.taskAgentWorkload;

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
                          if (isWide)
                            _buildWideLayout(
                              project, instances, briefs, briefCounts,
                              tasks, taskCounts, agentWork, events,
                              budgetData,
                            )
                          else
                            _buildNarrowLayout(
                              project, instances, briefs, briefCounts,
                              tasks, taskCounts, agentWork, events,
                              budgetData,
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildWideLayout(
    ProjectModel? project,
    List<InstanceModel> instances,
    List<BriefModel> briefs,
    Map<String, int> briefCounts,
    List<TaskModel> tasks,
    Map<String, int> taskCounts,
    Map<String, int> agentWork,
    List<BrainEventModel> events,
    ProjectBudgetModel? budgetData,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              ProjectHeaderCard(project: project),
              const SizedBox(height: FiftySpacing.sm),
              if (budgetData != null) ...[
                ProjectBudgetCard(budget: budgetData),
                const SizedBox(height: FiftySpacing.sm),
              ],
              ProjectInstancesPanel(instances: instances),
            ],
          ),
        ),
        const SizedBox(width: FiftySpacing.sm),
        Expanded(
          child: Column(
            children: [
              ProjectBriefsPanel(briefs: briefs, statusCounts: briefCounts),
              const SizedBox(height: FiftySpacing.sm),
              ProjectTasksPanel(
                tasks: tasks,
                statusCounts: taskCounts,
                agentWorkload: agentWork,
              ),
              const SizedBox(height: FiftySpacing.sm),
              ProjectEventsPanel(events: events),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(
    ProjectModel? project,
    List<InstanceModel> instances,
    List<BriefModel> briefs,
    Map<String, int> briefCounts,
    List<TaskModel> tasks,
    Map<String, int> taskCounts,
    Map<String, int> agentWork,
    List<BrainEventModel> events,
    ProjectBudgetModel? budgetData,
  ) {
    return Column(
      children: [
        ProjectHeaderCard(project: project),
        const SizedBox(height: FiftySpacing.sm),
        if (budgetData != null) ...[
          ProjectBudgetCard(budget: budgetData),
          const SizedBox(height: FiftySpacing.sm),
        ],
        ProjectInstancesPanel(instances: instances),
        const SizedBox(height: FiftySpacing.sm),
        ProjectBriefsPanel(briefs: briefs, statusCounts: briefCounts),
        const SizedBox(height: FiftySpacing.sm),
        ProjectTasksPanel(
          tasks: tasks,
          statusCounts: taskCounts,
          agentWorkload: agentWork,
        ),
        const SizedBox(height: FiftySpacing.sm),
        ProjectEventsPanel(events: events),
        const SizedBox(height: FiftySpacing.xxl),
      ],
    );
  }
}
