import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/arena_card.dart';
import '../../controllers/home_view_model.dart';

/// Summary card showing the most recent brain events in a compact list.
///
/// Displays up to 10 events with timestamp, component, and event name.
/// Tapping the card navigates to the Events page for full details.
class EventsSummaryCard extends StatelessWidget {
  const EventsSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Get.find<HomeViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Obx(() {
      final events = vm.recentEvents;

      return ArenaCard(
        title: 'RECENT EVENTS',
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 12,
          color: colorScheme.onSurfaceVariant,
        ),
        onTap: () => Get.toNamed(AppRoutes.events),
        child: events.isEmpty
            ? Text(
                'No recent events',
                style: textTheme.bodySmall!.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            : Column(
                children: events
                    .take(10)
                    .map((event) => _EventRow(
                          time: _formatTime(event.createdAt),
                          component: event.component,
                          eventName: event.eventName,
                          colorScheme: colorScheme,
                          textTheme: textTheme,
                        ))
                    .toList(),
              ),
      );
    });
  }

  /// Format an ISO timestamp to a compact HH:MM:SS display.
  static String _formatTime(String isoTimestamp) {
    try {
      final dt = DateTime.parse(isoTimestamp).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}:'
          '${dt.second.toString().padLeft(2, '0')}';
    } catch (_) {
      return '--:--:--';
    }
  }
}

/// A single compact event row: [time] [component] [event_name].
class _EventRow extends StatelessWidget {
  final String time;
  final String component;
  final String eventName;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _EventRow({
    required this.time,
    required this.component,
    required this.eventName,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          // Timestamp
          SizedBox(
            width: 64,
            child: Text(
              time,
              style: textTheme.labelSmall!.copyWith(
                fontFamily: 'monospace',
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(width: FiftySpacing.xs),
          // Component badge
          SizedBox(
            width: 80,
            child: Text(
              component,
              style: textTheme.labelSmall!.copyWith(
                fontWeight: FiftyTypography.bold,
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: FiftySpacing.xs),
          // Event name
          Expanded(
            child: Text(
              eventName,
              style: textTheme.labelSmall!.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
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
