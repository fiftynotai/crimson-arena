import 'dart:convert';

import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:fifty_ui/fifty_ui.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/arena_text_styles.dart';
import '../../../../data/models/brain_event_model.dart';
import '../../../../shared/utils/format_utils.dart';
import 'event_detail_modal.dart';

/// Component-to-color mapping for event badges.
///
/// Each brain component gets a distinct color for quick visual identification
/// in the live feed and history panels.
Color componentColor(String component) {
  switch (component) {
    case 'schedules':
      return const Color(0xFF4A9EFF); // blue
    case 'cache':
      return const Color(0xFF4ADE80); // green
    case 'coordination':
      return const Color(0xFFFB923C); // orange
    case 'tasks':
      return const Color(0xFFA78BFA); // purple
    case 'monitoring':
      return const Color(0xFFF472B6); // pink
    case 'sync':
      return const Color(0xFF38BDF8); // cyan
    case 'instances':
      return const Color(0xFFFBBF24); // yellow
    case 'briefs':
      return const Color(0xFFE879F9); // fuchsia
    case 'sessions':
      return const Color(0xFF34D399); // emerald
    case 'memory':
      return const Color(0xFF60A5FA); // light blue
    case 'errors':
      return const Color(0xFFEF4444); // red
    case 'projects':
      return const Color(0xFF818CF8); // indigo
    case 'metrics':
      return const Color(0xFF2DD4BF); // teal
    default:
      return const Color(0xFF94A3B8); // gray
  }
}

/// Compact card for a single live event in the live feed panel.
///
/// Shows timestamp, component badge, event name, and a truncated payload
/// summary. Uses a colored left border matching the component.
class LiveEventCard extends StatefulWidget {
  final BrainEventModel event;

  const LiveEventCard({super.key, required this.event});

  @override
  State<LiveEventCard> createState() => _LiveEventCardState();
}

class _LiveEventCardState extends State<LiveEventCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: FiftyMotion.compiling,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: FiftyMotion.enter,
    ));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: FiftyMotion.enter),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final event = widget.event;
    final color = componentColor(event.component);
    final timestamp = FormatUtils.formatTime(event.createdAt);
    final payloadSummary = _summarizePayload(event.payload);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: FiftySpacing.xs),
          child: GestureDetector(
            onTap: () => EventDetailModal.show(context, event),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: FiftyRadii.smRadius,
                  border: Border(
                    left: BorderSide(color: color, width: 3),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: FiftySpacing.sm,
                  vertical: FiftySpacing.xs,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timestamp
                    Text(
                      '[$timestamp]',
                      style: ArenaTextStyles.mono(
                        context,
                        fontSize: FiftyTypography.labelSmall,
                        fontWeight: FiftyTypography.medium,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(width: FiftySpacing.xs),

                    // Component badge
                    FiftyBadge(
                      label: event.component.toUpperCase(),
                      customColor: color,
                      showGlow: false,
                    ),
                    const SizedBox(width: FiftySpacing.xs),

                    // Event name + payload summary
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.eventName,
                            style: textTheme.labelSmall!.copyWith(
                              fontWeight: FiftyTypography.semiBold,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (payloadSummary.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              payloadSummary,
                              style: ArenaTextStyles.mono(
                                context,
                                fontSize: 10,
                                fontWeight: FiftyTypography.regular,
                                color:
                                    colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Context link indicator
                    if (event.hasContextLinks)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, top: 2),
                        child: Icon(
                          Icons.link,
                          size: 12,
                          color: colorScheme.primary.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Produce a compact one-line summary of the event payload.
  String _summarizePayload(Map<String, dynamic> payload) {
    if (payload.isEmpty) return '';
    try {
      final encoded = jsonEncode(payload);
      if (encoded.length <= 80) return encoded;
      return '${encoded.substring(0, 80)}...';
    } catch (_) {
      return '';
    }
  }
}
