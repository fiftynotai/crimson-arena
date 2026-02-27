import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:fifty_ui/fifty_ui.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/arena_text_styles.dart';
import '../../../../data/models/brain_event_model.dart';
import '../../../../shared/utils/format_utils.dart';
import '../../../../shared/widgets/arena_card.dart';
import '../../../events/views/widgets/live_event_card.dart';

/// Recent events panel for the Project Detail page.
///
/// Shows compact event rows with event name, component badge, and
/// timestamp in local timezone. Displays the last 20 events.
class ProjectEventsPanel extends StatelessWidget {
  /// The list of events to display.
  final List<BrainEventModel> events;

  const ProjectEventsPanel({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return ArenaCard(
      title: 'RECENT EVENTS',
      trailing: Text(
        '${events.length}',
        style: textTheme.labelSmall!.copyWith(
          fontWeight: FiftyTypography.bold,
          color: colorScheme.onSurface,
        ),
      ),
      child: events.isEmpty
          ? Text(
              'No events for this project',
              style: textTheme.bodySmall!.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: events.take(20).map((event) {
                return _CompactEventRow(event: event);
              }).toList(),
            ),
    );
  }
}

/// A single compact event row.
class _CompactEventRow extends StatelessWidget {
  final BrainEventModel event;

  const _CompactEventRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final color = componentColor(event.component);

    return Padding(
      padding: const EdgeInsets.only(bottom: FiftySpacing.xs),
      child: Row(
        children: [
          // Timestamp
          Text(
            FormatUtils.formatTime(event.createdAt),
            style: ArenaTextStyles.mono(
              context,
              fontSize: 10,
              fontWeight: FiftyTypography.medium,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
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

          // Event name
          Expanded(
            child: Text(
              event.eventName,
              style: textTheme.labelSmall!.copyWith(
                fontWeight: FiftyTypography.medium,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
