import 'package:crimson_arena/core/constants/arena_breakpoints.dart';
import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:fifty_ui/fifty_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/instance_model.dart';
import '../../../shared/widgets/arena_hover_button.dart';
import '../../../shared/widgets/arena_page_header.dart';
import '../../../shared/widgets/arena_scaffold.dart';
import '../controllers/instances_view_model.dart';
import 'widgets/agent_nexus_table.dart';
import 'widgets/compact_vitals_strip.dart';
import 'widgets/execution_log_widget.dart';
import 'widgets/hunt_pipeline_widget.dart';
import 'widgets/instance_card.dart';
import 'widgets/team_mode_widget.dart';

/// Instances page -- the operations floor showing real-time instance tracking.
///
/// Displays a compact vitals strip at the top, an instances header with
/// count badges, and a scrollable list of instance cards. Each card can
/// be expanded to show the hunt pipeline, agent nexus table, execution
/// log, and team mode widget (if applicable).
class InstancesPage extends StatefulWidget {
  const InstancesPage({super.key});

  @override
  State<InstancesPage> createState() => _InstancesPageState();
}

class _InstancesPageState extends State<InstancesPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final vm = Get.find<InstancesViewModel>();

    return ArenaScaffold(
      title: 'INSTANCES',
      activeTabIndex: 1,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < ArenaBreakpoints.narrow;
          final hPad = isNarrow ? FiftySpacing.sm : FiftySpacing.lg;

          return Column(
            children: [
              // Compact vitals strip
              const CompactVitalsStrip(),

              // Instances header
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: hPad,
                ).copyWith(top: FiftySpacing.sm),
                child: const FiftySectionHeader(
                  title: 'Active Instances',
                  size: FiftySectionHeaderSize.small,
                  showDivider: false,
                ),
              ),
              Obx(() => ArenaPageHeader(
                    title: 'INSTANCES',
                    summary:
                        '${vm.activeCount} active, ${vm.idleCount} idle',
                    onRefresh: vm.refreshData,
                    horizontalPadding: hPad,
                  )),

              // Instance list
              Expanded(
                child: Obx(() {
                  if (vm.isLoading.value) {
                    return const Center(
                      child: FiftyLoadingIndicator(
                        style: FiftyLoadingStyle.sequence,
                        size: FiftyLoadingSize.large,
                        sequences: [
                          '> SCANNING INSTANCES...',
                          '> READING PIPELINES...',
                          '> MAPPING AGENTS...',
                          '> READY.',
                        ],
                      ),
                    );
                  }

                  final instances = vm.instances;
                  // Read expandedInstanceId here so GetX tracks it.
                  // Reading it only inside itemBuilder (which runs during
                  // layout, not build) won't register a listener.
                  final expandedId = vm.expandedInstanceId.value;

                  if (instances.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return RefreshIndicator(
                    onRefresh: vm.refreshData,
                    color: colorScheme.primary,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    child: ListView.builder(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: hPad,
                        vertical: FiftySpacing.sm,
                      ),
                      itemCount: instances.length,
                      itemBuilder: (context, index) {
                        final instance = instances[index];
                        final isExpanded = expandedId == instance.id;

                        return InstanceCard(
                          instance: instance,
                          isExpanded: isExpanded,
                          onTap: () => vm.toggleInstance(instance.id),
                          expandedContent: isExpanded
                              ? _buildExpandedContent(vm, instance.id)
                              : null,
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExpandedContent(InstancesViewModel vm, String instanceId) {
    return Obx(() {
      final nexusData = vm.agentNexus[instanceId] ?? [];
      final logEntries = vm.executionLogs[instanceId] ?? [];
      final retries = vm.retryCounts[instanceId] ?? 0;
      final instance = vm.instances.firstWhere((i) => i.id == instanceId);
      final teamData = vm.teamStatus.value;
      final isTeamLead = teamData != null && teamData.active;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: FiftySpacing.sm),

          // Drill-down actions
          _buildDrillDownActions(context, instance),
          const SizedBox(height: FiftySpacing.sm),

          // Hunt pipeline
          HuntPipelineWidget(instance: instance),
          const SizedBox(height: FiftySpacing.sm),

          // Agent nexus table
          AgentNexusTable(
            instanceId: instanceId,
            nexusData: nexusData,
          ),
          const SizedBox(height: FiftySpacing.sm),

          // Execution log
          ExecutionLogWidget(
            instanceId: instanceId,
            entries: logEntries,
            retryCount: retries,
          ),

          // Team mode (if team lead)
          if (isTeamLead) ...[
            const SizedBox(height: FiftySpacing.sm),
            TeamModeWidget(teamStatus: teamData),
          ],
        ],
      );
    });
  }

  Widget _buildDrillDownActions(
    BuildContext context,
    InstanceModel instance,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Row(
      children: [
        ArenaHoverButton(
          onTap: () => Get.offNamed(
            '/instances/${Uri.encodeComponent(instance.id)}',
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.open_in_new, size: 14, color: colorScheme.primary),
              const SizedBox(width: FiftySpacing.xs),
              Text(
                'VIEW DETAIL',
                style: textTheme.labelSmall!.copyWith(
                  fontWeight: FiftyTypography.bold,
                  color: colorScheme.primary,
                  letterSpacing: FiftyTypography.letterSpacingLabelMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: FiftySpacing.md),
        ArenaHoverButton(
          onTap: () => Get.offNamed(
            '/events?instance=${Uri.encodeComponent(instance.id)}'
            '&hostname=${Uri.encodeComponent(instance.machineHostname)}'
            '&project=${Uri.encodeComponent(instance.projectSlug)}',
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt, size: 14, color: colorScheme.primary),
              const SizedBox(width: FiftySpacing.xs),
              Text(
                'EVENTS',
                style: textTheme.labelSmall!.copyWith(
                  fontWeight: FiftyTypography.bold,
                  color: colorScheme.primary,
                  letterSpacing: FiftyTypography.letterSpacingLabelMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: FiftySpacing.md),
        ArenaHoverButton(
          onTap: () => Get.offNamed(
            '/tasks?instance=${Uri.encodeComponent(instance.id)}'
            '&hostname=${Uri.encodeComponent(instance.machineHostname)}'
            '&project=${Uri.encodeComponent(instance.projectSlug)}',
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.assignment, size: 14, color: colorScheme.primary),
              const SizedBox(width: FiftySpacing.xs),
              Text(
                'TASKS',
                style: textTheme.labelSmall!.copyWith(
                  fontWeight: FiftyTypography.bold,
                  color: colorScheme.primary,
                  letterSpacing: FiftyTypography.letterSpacingLabelMedium,
                ),
              ),
            ],
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
              'NO ACTIVE SESSIONS',
              style: textTheme.titleLarge!.copyWith(
                fontWeight: FiftyTypography.extraBold,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                letterSpacing: FiftyTypography.letterSpacingLabelMedium,
              ),
            ),
            const SizedBox(height: FiftySpacing.sm),
            Text(
              '> Start a Claude Code session with /awaken to see instances here.',
              style: textTheme.bodyMedium!.copyWith(
                fontWeight: FiftyTypography.medium,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: FiftySpacing.xs),
            Text(
              '> Instances auto-expire after 4 hours of inactivity.',
              style: textTheme.bodySmall!.copyWith(
                fontWeight: FiftyTypography.regular,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

