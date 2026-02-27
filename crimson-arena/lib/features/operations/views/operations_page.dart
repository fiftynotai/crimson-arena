import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:fifty_ui/fifty_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/arena_breakpoints.dart';
import '../../../shared/widgets/arena_scaffold.dart';
import '../controllers/operations_view_model.dart';
import 'widgets/brain_health_panel.dart';
import 'widgets/knowledge_panel.dart';
import 'widgets/projects_panel.dart';
import 'widgets/sessions_panel.dart';
import 'widgets/sync_status_panel.dart';

/// Operations page -- brain infrastructure and ops dashboard.
///
/// Displays five panels:
/// 1. Brain health (DB status, uptime, memory)
/// 2. Sync status (push/pull, queue, online/offline)
/// 3. Knowledge base (entry counts, categories)
/// 4. Registered projects
/// 5. Recent sessions
///
/// Layout:
/// - Wide (>900px): two columns side by side
/// - Narrow (<900px): single column stacked
class OperationsPage extends StatelessWidget {
  const OperationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ArenaScaffold(
      title: 'OPERATIONS',
      activeTabIndex: 7,
      body: GetX<OperationsViewModel>(
        builder: (controller) {
          if (controller.isLoading.value) {
            return const Center(
              child: FiftyLoadingIndicator(
                style: FiftyLoadingStyle.sequence,
                size: FiftyLoadingSize.large,
                sequences: [
                  '> CONNECTING TO BRAIN...',
                  '> LOADING OPERATIONS DATA...',
                  '> CHECKING SYNC STATUS...',
                  '> READY.',
                ],
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > ArenaBreakpoints.wide;
              final isNarrow =
                  constraints.maxWidth < ArenaBreakpoints.narrow;
              final pagePad =
                  isNarrow ? FiftySpacing.sm : FiftySpacing.md;

              return SingleChildScrollView(
                padding: EdgeInsets.all(pagePad),
                child: isWide
                    ? _buildWideLayout(controller)
                    : _buildNarrowLayout(controller),
              );
            },
          );
        },
      ),
    );
  }

  /// Wide layout: two columns side by side.
  Widget _buildWideLayout(OperationsViewModel vm) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column: health, sync, knowledge
        Expanded(
          child: Column(
            children: [
              Obx(() => BrainHealthPanel(data: vm.brainHealth.value)),
              const SizedBox(height: FiftySpacing.sm),
              Obx(() => SyncStatusPanel(data: vm.syncStatus.value)),
              const SizedBox(height: FiftySpacing.sm),
              Obx(() => KnowledgePanel(data: vm.knowledgeState.value)),
            ],
          ),
        ),
        const SizedBox(width: FiftySpacing.sm),
        // Right column: projects, sessions
        Expanded(
          child: Column(
            children: [
              Obx(() => ProjectsPanel(projects: vm.projects)),
              const SizedBox(height: FiftySpacing.sm),
              Obx(() => SessionsPanel(sessions: vm.sessions)),
            ],
          ),
        ),
      ],
    );
  }

  /// Narrow layout: single column stacked.
  Widget _buildNarrowLayout(OperationsViewModel vm) {
    return Column(
      children: [
        Obx(() => BrainHealthPanel(data: vm.brainHealth.value)),
        const SizedBox(height: FiftySpacing.sm),
        Obx(() => SyncStatusPanel(data: vm.syncStatus.value)),
        const SizedBox(height: FiftySpacing.sm),
        Obx(() => KnowledgePanel(data: vm.knowledgeState.value)),
        const SizedBox(height: FiftySpacing.sm),
        Obx(() => ProjectsPanel(projects: vm.projects)),
        const SizedBox(height: FiftySpacing.sm),
        Obx(() => SessionsPanel(sessions: vm.sessions)),
        const SizedBox(height: FiftySpacing.xxl),
      ],
    );
  }
}
