import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:fifty_ui/fifty_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/arena_breakpoints.dart';
import '../../../core/routing/app_routes.dart';
import '../../../shared/widgets/arena_card.dart';
import '../../../shared/widgets/arena_scaffold.dart';
import '../controllers/home_view_model.dart';
import 'widgets/brain_briefs_panel.dart';
import 'widgets/events_summary_card.dart';
import 'widgets/instances_summary_card.dart';
import 'widgets/tasks_summary_card.dart';

/// Home page -- the primary dashboard view.
///
/// Displays four focused panels:
/// 1. Instances summary card (active/idle/total)
/// 2. Tasks summary card (status counts)
/// 3. Events summary card (recent events list)
/// 4. Project briefs panel
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

                    // Quick link to Agents page
                    ArenaCard(
                      title: 'AGENTS',
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                      onTap: () => Get.toNamed(AppRoutes.agents),
                      child: Text(
                        'View agent roster, skill trees, and metrics',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                    const SizedBox(height: FiftySpacing.sm),

                    // Quick link to Operations page
                    ArenaCard(
                      title: 'OPERATIONS',
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                      onTap: () => Get.toNamed(AppRoutes.operations),
                      child: Text(
                        'Brain health, sync status, and infrastructure metrics',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),

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
