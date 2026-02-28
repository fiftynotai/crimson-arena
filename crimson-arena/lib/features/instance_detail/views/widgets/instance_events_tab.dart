import 'package:crimson_arena/core/theme/arena_text_styles.dart';
import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../shared/widgets/arena_hover_button.dart';
import '../../../events/views/widgets/live_event_card.dart';
import '../../controllers/instance_detail_view_model.dart';

/// Events tab for the Instance Detail page.
///
/// Displays brain events filtered by instance ID with server-side
/// pagination. Uses [LiveEventCard] for compact event rows and
/// [ArenaHoverButton] for PREV/NEXT pagination controls.
class InstanceEventsTab extends StatelessWidget {
  final InstanceDetailViewModel vm;

  const InstanceEventsTab({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final events = vm.instanceEvents.toList();
      final total = vm.eventTotal.value;
      final currentPage = vm.currentPage;
      final totalPages = vm.totalPages;
      final hasPrev = vm.hasPrevPage;
      final hasNext = vm.hasNextPage;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pagination header
          _buildPaginationHeader(
            context,
            total: total,
            currentPage: currentPage,
            totalPages: totalPages,
            hasPrev: hasPrev,
            hasNext: hasNext,
          ),

          // Event list
          Expanded(
            child: events.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      vertical: FiftySpacing.xs,
                    ),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      return LiveEventCard(event: events[index]);
                    },
                  ),
          ),
        ],
      );
    });
  }

  Widget _buildPaginationHeader(
    BuildContext context, {
    required int total,
    required int currentPage,
    required int totalPages,
    required bool hasPrev,
    required bool hasNext,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FiftySpacing.sm),
      child: Row(
        children: [
          Text(
            'EVENTS',
            style: textTheme.labelMedium!.copyWith(
              color: colorScheme.onSurfaceVariant,
              letterSpacing: FiftyTypography.letterSpacingLabelMedium,
            ),
          ),
          const SizedBox(width: FiftySpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: FiftySpacing.sm,
              vertical: FiftySpacing.xs,
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
              '$total total',
              style: ArenaTextStyles.mono(
                context,
                fontSize: FiftyTypography.labelSmall,
                fontWeight: FiftyTypography.semiBold,
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
          const Spacer(),

          // Pagination controls
          ArenaHoverButton(
            onTap: hasPrev ? vm.prevEventsPage : null,
            disabled: !hasPrev,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chevron_left,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                Text(
                  'PREV',
                  style: textTheme.labelSmall!.copyWith(
                    fontWeight: FiftyTypography.bold,
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: FiftyTypography.letterSpacingLabelMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: FiftySpacing.xs),
          Text(
            '$currentPage/$totalPages',
            style: ArenaTextStyles.mono(
              context,
              fontSize: FiftyTypography.labelSmall,
              fontWeight: FiftyTypography.medium,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: FiftySpacing.xs),
          ArenaHoverButton(
            onTap: hasNext ? vm.nextEventsPage : null,
            disabled: !hasNext,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'NEXT',
                  style: textTheme.labelSmall!.copyWith(
                    fontWeight: FiftyTypography.bold,
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: FiftyTypography.letterSpacingLabelMedium,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: FiftySpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'NO EVENTS',
              style: textTheme.titleLarge!.copyWith(
                fontWeight: FiftyTypography.extraBold,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                letterSpacing: FiftyTypography.letterSpacingLabelMedium,
              ),
            ),
            const SizedBox(height: FiftySpacing.sm),
            Text(
              '> No events have been recorded for this instance yet.',
              style: textTheme.bodyMedium!.copyWith(
                fontWeight: FiftyTypography.medium,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
