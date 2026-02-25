import 'dart:convert';

import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:fifty_ui/fifty_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/arena_text_styles.dart';
import '../../../../data/models/brain_event_model.dart';
import '../../../../shared/utils/format_utils.dart';
import '../../controllers/events_view_model.dart';
import 'live_event_card.dart';

/// Panel showing paginated event history from the REST API.
///
/// Each row is tappable to expand and show the full payload JSON.
/// Includes pagination controls at the bottom.
class EventHistoryPanel extends StatefulWidget {
  const EventHistoryPanel({super.key});

  @override
  State<EventHistoryPanel> createState() => _EventHistoryPanelState();
}

class _EventHistoryPanelState extends State<EventHistoryPanel> {
  /// Tracks which event ID is currently expanded to show full payload.
  final _expandedEventId = Rxn<int>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final vm = Get.find<EventsViewModel>();

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
                Text(
                  'EVENT HISTORY',
                  style: textTheme.labelMedium!.copyWith(
                    fontWeight: FiftyTypography.extraBold,
                    color: colorScheme.onSurface,
                    letterSpacing: FiftyTypography.letterSpacingLabelMedium,
                  ),
                ),
                const SizedBox(width: FiftySpacing.sm),

                // Total count badge
                Obx(() {
                  final total = vm.historyTotal.value;
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
                      '${FormatUtils.formatNumber(total)} total',
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

                // Refresh button
                _HoverButton(
                  onTap: vm.fetchHistory,
                  child: Text(
                    'REFRESH',
                    style: textTheme.labelSmall!.copyWith(
                      fontWeight: FiftyTypography.bold,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: FiftyTypography.letterSpacingLabelMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table header row
          _buildTableHeader(context),

          // Event rows
          Expanded(
            child: Obx(() {
              if (vm.isLoadingHistory.value) {
                return const Center(
                  child: FiftyLoadingIndicator(
                    style: FiftyLoadingStyle.sequence,
                    size: FiftyLoadingSize.medium,
                    sequences: [
                      '> QUERYING EVENTS...',
                      '> LOADING...',
                    ],
                  ),
                );
              }

              final events = vm.historyEvents;

              if (events.isEmpty) {
                return Center(
                  child: Text(
                    '> No events found',
                    style: ArenaTextStyles.mono(
                      context,
                      fontSize: FiftyTypography.bodySmall,
                      fontWeight: FiftyTypography.medium,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ),
                );
              }

              return ListView.builder(
                physics: const ClampingScrollPhysics(),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Obx(() {
                    final isExpanded = _expandedEventId.value == event.id;
                    return _EventHistoryRow(
                      event: event,
                      isExpanded: isExpanded,
                      onTap: () {
                        _expandedEventId.value = isExpanded ? null : event.id;
                      },
                    );
                  });
                },
              );
            }),
          ),

          // Pagination controls
          _buildPaginationBar(context, vm),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FiftySpacing.md,
        vertical: FiftySpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _headerCell(context, 'TIME', width: 80),
          _headerCell(context, 'COMPONENT', width: 100),
          _headerCell(context, 'EVENT', flex: 2),
          _headerCell(context, 'PROJECT', flex: 1),
          _headerCell(context, 'PAYLOAD', flex: 2),
        ],
      ),
    );
  }

  Widget _headerCell(
    BuildContext context,
    String label, {
    double? width,
    int? flex,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final text = Text(
      label,
      style: ArenaTextStyles.mono(
        context,
        fontSize: 10,
        fontWeight: FiftyTypography.bold,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        letterSpacing: 1.0,
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: text);
    }
    return Expanded(flex: flex ?? 1, child: text);
  }

  Widget _buildPaginationBar(BuildContext context, EventsViewModel vm) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FiftySpacing.md,
        vertical: FiftySpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outline,
            width: 1,
          ),
        ),
      ),
      child: Obx(() {
        final offset = vm.historyOffset.value;
        final limit = vm.historyLimit.value;
        final total = vm.historyTotal.value;
        final from = total == 0 ? 0 : offset + 1;
        final to = (offset + limit).clamp(0, total);
        final hasPrev = offset > 0;
        final hasNext = offset + limit < total;

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '$from-$to of ${FormatUtils.formatNumber(total)}',
              style: ArenaTextStyles.mono(
                context,
                fontSize: FiftyTypography.labelSmall,
                fontWeight: FiftyTypography.medium,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: FiftySpacing.md),

            _HoverButton(
              onTap: hasPrev ? vm.prevPage : null,
              child: Text(
                '< PREV',
                style: ArenaTextStyles.mono(
                  context,
                  fontSize: FiftyTypography.labelSmall,
                  fontWeight: FiftyTypography.bold,
                  color: hasPrev
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            const SizedBox(width: FiftySpacing.sm),

            _HoverButton(
              onTap: hasNext ? vm.nextPage : null,
              child: Text(
                'NEXT >',
                style: ArenaTextStyles.mono(
                  context,
                  fontSize: FiftyTypography.labelSmall,
                  fontWeight: FiftyTypography.bold,
                  color: hasNext
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// A single row in the event history table.
class _EventHistoryRow extends StatelessWidget {
  final BrainEventModel event;
  final bool isExpanded;
  final VoidCallback onTap;

  const _EventHistoryRow({
    required this.event,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = componentColor(event.component);
    final timestamp = FormatUtils.formatTime(event.createdAt);
    final payloadStr = _compactPayload(event.payload);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main row
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: FiftySpacing.md,
              vertical: FiftySpacing.xs + 2,
            ),
            decoration: BoxDecoration(
              color: isExpanded
                  ? colorScheme.primary.withValues(alpha: 0.05)
                  : Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Time
                SizedBox(
                  width: 80,
                  child: Text(
                    timestamp,
                    style: ArenaTextStyles.mono(
                      context,
                      fontSize: FiftyTypography.labelSmall,
                      fontWeight: FiftyTypography.medium,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),

                // Component
                SizedBox(
                  width: 100,
                  child: FiftyBadge(
                    label: event.component,
                    customColor: color,
                    showGlow: false,
                  ),
                ),

                // Event name
                Expanded(
                  flex: 2,
                  child: Text(
                    event.eventName,
                    style: ArenaTextStyles.mono(
                      context,
                      fontSize: FiftyTypography.labelSmall,
                      fontWeight: FiftyTypography.semiBold,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Project
                Expanded(
                  flex: 1,
                  child: Text(
                    event.projectSlug ?? '--',
                    style: ArenaTextStyles.mono(
                      context,
                      fontSize: FiftyTypography.labelSmall,
                      fontWeight: FiftyTypography.medium,
                      color: colorScheme.primary.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Payload summary
                Expanded(
                  flex: 2,
                  child: Text(
                    payloadStr,
                    style: ArenaTextStyles.mono(
                      context,
                      fontSize: 10,
                      fontWeight: FiftyTypography.regular,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Expand indicator
                Text(
                  isExpanded ? '[-]' : '[+]',
                  style: ArenaTextStyles.mono(
                    context,
                    fontSize: FiftyTypography.labelSmall,
                    fontWeight: FiftyTypography.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expanded payload
        if (isExpanded)
          _buildExpandedPayload(context, colorScheme),
      ],
    );
  }

  Widget _buildExpandedPayload(BuildContext context, ColorScheme colorScheme) {
    final prettyPayload = _prettyPayload(event.payload);

    return AnimatedSize(
      duration: FiftyMotion.fast,
      curve: FiftyMotion.standard,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(FiftySpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
        child: SelectableText(
          prettyPayload,
          style: ArenaTextStyles.mono(
            context,
            fontSize: 11,
            fontWeight: FiftyTypography.regular,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            height: 1.4,
          ),
        ),
      ),
    );
  }

  String _compactPayload(Map<String, dynamic> payload) {
    if (payload.isEmpty) return '--';
    try {
      final encoded = jsonEncode(payload);
      if (encoded.length <= 60) return encoded;
      return '${encoded.substring(0, 60)}...';
    } catch (_) {
      return '--';
    }
  }

  String _prettyPayload(Map<String, dynamic> payload) {
    if (payload.isEmpty) return '{}';
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(payload);
    } catch (_) {
      return jsonEncode(payload);
    }
  }
}

/// A button with hover feedback.
class _HoverButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;

  const _HoverButton({this.onTap, required this.child});

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: FiftySpacing.sm,
            vertical: FiftySpacing.xs,
          ),
          decoration: BoxDecoration(
            color: _hovered && widget.onTap != null
                ? colorScheme.onSurface.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: FiftyRadii.smRadius,
            border: Border.all(
              color: _hovered && widget.onTap != null
                  ? colorScheme.outline
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
