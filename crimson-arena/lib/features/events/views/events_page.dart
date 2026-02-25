import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:fifty_ui/fifty_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/arena_breakpoints.dart';
import '../../../shared/widgets/arena_scaffold.dart';
import '../controllers/events_view_model.dart';
import 'widgets/event_filter_bar.dart';
import 'widgets/event_history_panel.dart';
import 'widgets/live_feed_panel.dart';

/// Events page -- brain event log viewer with live feed and history.
///
/// Layout:
/// - Filter bar across the top (component chips + search)
/// - Wide screens (>900px): side-by-side panels (40% live, 60% history)
/// - Narrow screens (<900px): stacked panels
class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

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
