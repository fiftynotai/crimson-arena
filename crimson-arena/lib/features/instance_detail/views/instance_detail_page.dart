import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:fifty_ui/fifty_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/arena_breakpoints.dart';
import '../../../core/routing/app_routes.dart';
import '../../../data/models/instance_model.dart';
import '../../../shared/widgets/arena_breadcrumb.dart';
import '../../../shared/widgets/arena_page_header.dart';
import '../../../shared/widgets/arena_scaffold.dart';
import '../controllers/instance_detail_view_model.dart';
import 'widgets/instance_agents_tab.dart';
import 'widgets/instance_events_tab.dart';
import 'widgets/instance_hunt_tab.dart';
import 'widgets/instance_tasks_tab.dart';

/// Instance Detail page -- scoped view for a single Claude Code instance.
///
/// Reads the `:id` route parameter and loads all data scoped to that
/// instance. Displays a header card and 4 tabs: HUNT, AGENTS, EVENTS,
/// TASKS.
///
/// Layout follows the same patterns as [ProjectDetailPage] with
/// [ArenaScaffold], breadcrumbs, and [DefaultTabController].
class InstanceDetailPage extends StatefulWidget {
  const InstanceDetailPage({super.key});

  @override
  State<InstanceDetailPage> createState() => _InstanceDetailPageState();
}

class _InstanceDetailPageState extends State<InstanceDetailPage> {
  @override
  void initState() {
    super.initState();
    final instanceId = Get.parameters['id'] ?? '';
    if (instanceId.isNotEmpty) {
      Get.find<InstanceDetailViewModel>().loadInstance(instanceId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final instanceId = Get.parameters['id'] ?? '';
    final vm = Get.find<InstanceDetailViewModel>();

    return ArenaScaffold(
      title: 'INSTANCE',
      activeTabIndex: 1,
      breadcrumbs: [
        BreadcrumbSegment(label: 'HOME', route: AppRoutes.home),
        BreadcrumbSegment(label: 'INSTANCES', route: AppRoutes.instances),
        BreadcrumbSegment(label: instanceId),
      ],
      body: instanceId.isEmpty
          ? Center(
              child: Text(
                'No instance ID provided.',
                style: textTheme.bodyMedium!.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : Obx(() {
              if (vm.isLoading.value) {
                return const Center(
                  child: FiftyLoadingIndicator(
                    style: FiftyLoadingStyle.sequence,
                    size: FiftyLoadingSize.large,
                    sequences: [
                      '> LOADING INSTANCE...',
                      '> READING PIPELINE...',
                      '> MAPPING AGENTS...',
                      '> SCANNING EVENTS...',
                      '> READY.',
                    ],
                  ),
                );
              }

              final instance = vm.instance.value;
              if (instance == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'INSTANCE NOT FOUND',
                        style: textTheme.titleLarge!.copyWith(
                          fontWeight: FiftyTypography.extraBold,
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.5),
                          letterSpacing:
                              FiftyTypography.letterSpacingLabelMedium,
                        ),
                      ),
                      const SizedBox(height: FiftySpacing.sm),
                      Text(
                        '> Instance "$instanceId" is no longer registered.',
                        style: textTheme.bodyMedium!.copyWith(
                          fontWeight: FiftyTypography.medium,
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return _buildContent(context, vm, instance);
            }),
    );
  }

  Widget _buildContent(
    BuildContext context,
    InstanceDetailViewModel vm,
    InstanceModel instance,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < ArenaBreakpoints.narrow;
        final hPad = isNarrow ? FiftySpacing.sm : FiftySpacing.lg;

        return DefaultTabController(
          length: 4,
          child: Column(
            children: [
              // Page header with refresh
              ArenaPageHeader(
                title: 'INSTANCE DETAIL',
                summary: instance.displayLabel,
                onRefresh: vm.refreshData,
                horizontalPadding: hPad,
              ),

              // Instance header card
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: _buildInstanceHeader(context, vm),
              ),
              const SizedBox(height: FiftySpacing.sm),

              // Tab bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: _buildTabBar(context),
              ),

              // Tab content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: TabBarView(
                    children: [
                      InstanceHuntTab(vm: vm),
                      InstanceAgentsTab(vm: vm),
                      InstanceEventsTab(vm: vm),
                      InstanceTasksTab(vm: vm),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstanceHeader(
    BuildContext context,
    InstanceDetailViewModel vm,
  ) {
    return Obx(() {
      final instance = vm.instance.value;
      if (instance == null) return const SizedBox.shrink();

      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      final ext = theme.extension<FiftyThemeExtension>()!;

      return Container(
        padding: const EdgeInsets.all(FiftySpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: FiftyRadii.mdRadius,
          border: Border.all(
            color: instance.isActive
                ? colorScheme.primary.withValues(alpha: 0.4)
                : colorScheme.outline,
            width: instance.isActive ? 1.5 : 1,
          ),
          boxShadow: instance.isActive
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Wrap(
          spacing: FiftySpacing.lg,
          runSpacing: FiftySpacing.sm,
          children: [
            _headerField(
              context,
              'STATUS',
              instance.status.toUpperCase(),
              color: instance.isActive
                  ? ext.success
                  : colorScheme.onSurfaceVariant,
            ),
            _headerField(
              context,
              'HOSTNAME',
              instance.machineHostname.isNotEmpty
                  ? instance.machineHostname
                  : '--',
            ),
            _headerField(
              context,
              'PROJECT',
              instance.projectSlug.isNotEmpty
                  ? instance.projectSlug.toUpperCase()
                  : '--',
              color: colorScheme.primary,
            ),
            _headerField(
              context,
              'BRIEF',
              instance.currentBrief ?? '--',
            ),
            _headerField(
              context,
              'PHASE',
              (instance.currentPhase ?? '--').toUpperCase(),
              color: colorScheme.primary,
            ),
            _headerField(
              context,
              'HEARTBEAT',
              _relativeTime(instance.lastHeartbeat),
            ),
          ],
        ),
      );
    });
  }

  Widget _headerField(
    BuildContext context,
    String label,
    String value, {
    Color? color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: textTheme.labelSmall!.copyWith(
            color: colorScheme.onSurfaceVariant,
            letterSpacing: FiftyTypography.letterSpacingLabelMedium,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: textTheme.bodySmall!.copyWith(
            fontWeight: FiftyTypography.bold,
            color: color ?? colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline,
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: colorScheme.onSurface,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: textTheme.labelMedium!.copyWith(
          fontWeight: FiftyTypography.bold,
          letterSpacing: FiftyTypography.letterSpacingLabelMedium,
        ),
        unselectedLabelStyle: textTheme.labelMedium!.copyWith(
          fontWeight: FiftyTypography.medium,
          letterSpacing: FiftyTypography.letterSpacingLabelMedium,
        ),
        indicatorColor: colorScheme.primary,
        indicatorWeight: 2,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'HUNT'),
          Tab(text: 'AGENTS'),
          Tab(text: 'EVENTS'),
          Tab(text: 'TASKS'),
        ],
      ),
    );
  }

  String _relativeTime(String? timestamp) {
    if (timestamp == null) return '--';
    final heartbeat = DateTime.tryParse(timestamp);
    if (heartbeat == null) return '--';

    final diff = DateTime.now().toUtc().difference(heartbeat);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
