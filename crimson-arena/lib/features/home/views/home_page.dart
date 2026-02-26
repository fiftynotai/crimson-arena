import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:fifty_ui/fifty_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/arena_breakpoints.dart';
import '../../../shared/widgets/arena_scaffold.dart';
import '../controllers/home_view_model.dart';
import 'widgets/agent_roster_strip.dart';
import 'widgets/brain_briefs_panel.dart';
import 'widgets/events_summary_card.dart';
import 'widgets/instances_summary_card.dart';
import 'widgets/tasks_summary_card.dart';

/// Home page -- the primary dashboard view.
///
/// Displays five focused panels:
/// 1. Instances summary card (active/idle/total)
/// 2. Tasks summary card (status counts)
/// 3. Events summary card (recent events list)
/// 4. Project briefs panel
/// 5. Agent roster strip
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ArenaScaffold(
      title: 'HOME',
      activeTabIndex: 0,
      body: GetX<HomeViewModel>(
        builder: (controller) {
          if (controller.isLoading.value) {
            return const Center(
              child: FiftyLoadingIndicator(
                style: FiftyLoadingStyle.sequence,
                size: FiftyLoadingSize.large,
                sequences: [
                  '> CONNECTING TO BRAIN...',
                  '> LOADING DASHBOARD...',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary cards: row on wide, column on narrow
                    if (isWide)
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: InstancesSummaryCard()),
                          SizedBox(width: FiftySpacing.sm),
                          Expanded(child: TasksSummaryCard()),
                          SizedBox(width: FiftySpacing.sm),
                          Expanded(child: EventsSummaryCard()),
                        ],
                      )
                    else
                      const Column(
                        children: [
                          InstancesSummaryCard(),
                          SizedBox(height: FiftySpacing.sm),
                          TasksSummaryCard(),
                          SizedBox(height: FiftySpacing.sm),
                          EventsSummaryCard(),
                        ],
                      ),
                    const SizedBox(height: FiftySpacing.md),

                    // Project briefs
                    Obx(() => BrainBriefsPanel(
                          briefs: controller.brainBriefs,
                          statusCounts: controller.briefStatusCounts,
                        )),
                    const SizedBox(height: FiftySpacing.md),

                    // Agent roster strip
                    const AgentRosterStrip(),

                    // Bottom padding
                    const SizedBox(height: FiftySpacing.xxl),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
