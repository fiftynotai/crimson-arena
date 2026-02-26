import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:fifty_ui/fifty_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/arena_breakpoints.dart';
import '../../../core/theme/arena_text_styles.dart';
import '../../../shared/widgets/arena_hover_button.dart';
import '../../../shared/widgets/arena_scaffold.dart';
import '../controllers/events_view_model.dart';
import 'widgets/event_filter_bar.dart';
import 'widgets/event_history_panel.dart';
import 'widgets/live_feed_panel.dart';

/// Events page -- brain event log viewer with live feed and history.
///
/// Layout:
/// - Instance context banner (when drilled from Instances page)
/// - Filter bar across the top (component chips + search)
/// - Wide screens (>900px): side-by-side panels (40% live, 60% history)
/// - Narrow screens (<900px): stacked panels
class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  @override
  void initState() {
    super.initState();
    _handleDeepLink();
  }

  void _handleDeepLink() {
    final params = Get.parameters;
    final instanceId = params['instance'];
    final vm = Get.find<EventsViewModel>();
    if (instanceId != null && instanceId.isNotEmpty) {
      vm.setInstanceFilter(
        instanceId,
        hostname: params['hostname'],
        project: params['project'],
      );
    } else {
      // Clear leftover instance filter from previous navigation.
      if (vm.hasInstanceFilter) vm.setInstanceFilter(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ArenaScaffold(
      title: 'EVENTS',
      activeTabIndex: 2,
      body: GetX<EventsViewModel>(
        builder: (controller) {
          if (controller.isLoading.value) {
            return const Center(
              child: FiftyLoadingIndicator(
                style: FiftyLoadingStyle.sequence,
                size: FiftyLoadingSize.large,
                sequences: [
                  '> CONNECTING TO EVENT STREAM...',
                  '> LOADING BRAIN EVENTS...',
                  '> READY.',
                ],
              ),
            );
          }

          return _buildContent(context);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final vm = Get.find<EventsViewModel>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > ArenaBreakpoints.wide;
        final isNarrow = constraints.maxWidth < ArenaBreakpoints.narrow;
        final hPad = isNarrow ? FiftySpacing.sm : FiftySpacing.lg;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: hPad,
            vertical: FiftySpacing.sm,
          ),
          child: Column(
            children: [
              // Instance context banner
              Obx(() {
                if (!vm.hasInstanceFilter) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: FiftySpacing.sm),
                  child: _buildInstanceBanner(context, vm),
                );
              }),

              // Filter bar
              const EventFilterBar(),
              const SizedBox(height: FiftySpacing.sm),

              // Main content panels
              Expanded(
                child: isWide
                    ? _buildWideLayout()
                    : _buildNarrowLayout(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstanceBanner(BuildContext context, EventsViewModel vm) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final hostname = vm.instanceHostname.value;
    final project = vm.instanceProject.value;
    final instanceId = vm.selectedInstanceId.value ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FiftySpacing.md,
        vertical: FiftySpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: FiftyRadii.mdRadius,
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_alt,
            size: 14,
            color: colorScheme.primary,
          ),
          const SizedBox(width: FiftySpacing.sm),
          Text(
            'INSTANCE:',
            style: textTheme.labelSmall!.copyWith(
              fontWeight: FiftyTypography.bold,
              color: colorScheme.primary,
              letterSpacing: FiftyTypography.letterSpacingLabelMedium,
            ),
          ),
          const SizedBox(width: FiftySpacing.xs),
          Text(
            hostname ?? instanceId.substring(0, instanceId.length.clamp(0, 8)),
            style: ArenaTextStyles.mono(
              context,
              fontSize: FiftyTypography.labelSmall,
              fontWeight: FiftyTypography.semiBold,
              color: colorScheme.onSurface,
            ),
          ),
          if (project != null) ...[
            const SizedBox(width: FiftySpacing.xs),
            Text(
              '/',
              style: textTheme.labelSmall!.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: FiftySpacing.xs),
            Text(
              project.toUpperCase(),
              style: ArenaTextStyles.mono(
                context,
                fontSize: FiftyTypography.labelSmall,
                fontWeight: FiftyTypography.semiBold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
          const Spacer(),
          ArenaHoverButton(
            onTap: () => vm.setInstanceFilter(null),
            child: Icon(
              Icons.close,
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Wide layout: side-by-side panels (40% live feed, 60% history).
  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Live feed panel (40%)
        const Expanded(
          flex: 4,
          child: LiveFeedPanel(),
        ),
        const SizedBox(width: FiftySpacing.sm),

        // History panel (60%)
        const Expanded(
          flex: 6,
          child: EventHistoryPanel(),
        ),
      ],
    );
  }

  /// Narrow layout: stacked panels (live feed on top, history below).
  Widget _buildNarrowLayout() {
    return const Column(
      children: [
        // Live feed (fixed height)
        SizedBox(
          height: 300,
          child: LiveFeedPanel(),
        ),
        SizedBox(height: FiftySpacing.sm),

        // History (fills remaining space)
        Expanded(
          child: EventHistoryPanel(),
        ),
      ],
    );
  }
}
