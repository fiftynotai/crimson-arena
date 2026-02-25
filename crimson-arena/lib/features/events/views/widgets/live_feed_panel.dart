import 'package:fifty_theme/fifty_theme.dart';
import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/arena_text_styles.dart';
import '../../../../services/brain_websocket_service.dart';
import '../../controllers/events_view_model.dart';
import 'live_event_card.dart';

/// Panel showing the real-time event stream from the WebSocket connection.
///
/// Features:
/// - Pulsing green dot when connected, red when disconnected.
/// - Auto-scrolls to top when new events arrive (unless paused).
/// - Pauses auto-scroll on mouse hover.
/// - Shows "Waiting for events..." when the feed is empty.
class LiveFeedPanel extends StatefulWidget {
  const LiveFeedPanel({super.key});

  @override
  State<LiveFeedPanel> createState() => _LiveFeedPanelState();
}

class _LiveFeedPanelState extends State<LiveFeedPanel> {
  final ScrollController _scrollController = ScrollController();
  final _vm = Get.find<EventsViewModel>();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (!_vm.isPaused.value && _scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: FiftyMotion.fast,
        curve: FiftyMotion.enter,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final ext = theme.extension<FiftyThemeExtension>()!;
    final ws = Get.find<BrainWebSocketService>();

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: FiftyRadii.mdRadius,
        border: Border.all(
          color: colorScheme.outline,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: FiftySpacing.md,
              vertical: FiftySpacing.sm,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Pulsing status dot
                Obx(() {
                  final connected = ws.isConnected.value;
                  return _PulsingDot(
                    color: connected ? ext.success : colorScheme.error,
                    isPulsing: connected,
                  );
                }),
                const SizedBox(width: FiftySpacing.xs),

                Text(
                  'LIVE FEED',
                  style: textTheme.labelMedium!.copyWith(
                    fontWeight: FiftyTypography.extraBold,
                    color: colorScheme.onSurface,
                    letterSpacing: FiftyTypography.letterSpacingLabelMedium,
                  ),
                ),
                const SizedBox(width: FiftySpacing.sm),

                // Event count badge
                Obx(() {
                  final count = _vm.liveEvents.length;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: FiftySpacing.xs,
                      vertical: 2,
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
                      '$count',
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

                // Pause indicator
                Obx(() {
                  if (!_vm.isPaused.value) return const SizedBox.shrink();
                  return Text(
                    'PAUSED',
                    style: textTheme.labelSmall!.copyWith(
                      fontWeight: FiftyTypography.bold,
                      color: ext.warning,
                      letterSpacing: FiftyTypography.letterSpacingLabel,
                    ),
                  );
                }),
              ],
            ),
          ),

          // Event list
          Expanded(
            child: MouseRegion(
              onEnter: (_) => _vm.isPaused.value = true,
              onExit: (_) => _vm.isPaused.value = false,
              child: Obx(() {
                final events = _vm.liveEvents;

                // Trigger scroll-to-top when events change (if not paused).
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToTop();
                });

                if (events.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '> Waiting for events...',
                          style: ArenaTextStyles.mono(
                            context,
                            fontSize: FiftyTypography.bodySmall,
                            fontWeight: FiftyTypography.medium,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.all(FiftySpacing.sm),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    return LiveEventCard(event: events[index]);
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small dot with an optional pulsing glow animation.
class _PulsingDot extends StatefulWidget {
  final Color color;
  final bool isPulsing;

  const _PulsingDot({
    required this.color,
    required this.isPulsing,
  });

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isPulsing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_PulsingDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPulsing && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: widget.isPulsing
                ? [
                    BoxShadow(
                      color:
                          widget.color.withValues(alpha: _animation.value * 0.6),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }
}
