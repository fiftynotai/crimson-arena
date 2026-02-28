import 'dart:convert';

import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:fifty_ui/fifty_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/arena_text_styles.dart';
import '../../../../data/models/brain_event_model.dart';
import '../../../../shared/utils/format_utils.dart';
import 'event_context_chips.dart';
import 'live_event_card.dart';

/// A detail modal dialog for inspecting a single brain event.
///
/// Displays all event fields in a structured layout: event name, component
/// and time badges, info rows for linked context (project, instance, brief,
/// task), and a pretty-printed JSON payload section.
///
/// Follows the same structural pattern as [TaskDetailModal]:
/// transparent Dialog > ConstrainedBox > surfaceContainerHighest container.
class EventDetailModal extends StatelessWidget {
  /// The event to display in detail.
  final BrainEventModel event;

  const EventDetailModal({super.key, required this.event});

  /// Shows the [EventDetailModal] as a centered dialog.
  static void show(BuildContext context, BrainEventModel event) {
    showDialog<void>(
      context: context,
      builder: (_) => EventDetailModal(event: event),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final color = componentColor(event.component);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: FiftyRadii.lgRadius,
            border: Border.all(color: colorScheme.outline),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(FiftySpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header row with label and close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'EVENT DETAIL',
                      style: textTheme.labelSmall!.copyWith(
                        fontWeight: FiftyTypography.bold,
                        color: colorScheme.onSurfaceVariant,
                        letterSpacing: FiftyTypography.letterSpacingLabel,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: FiftySpacing.md),

                // Event name
                Text(
                  event.eventName,
                  style: textTheme.titleMedium!.copyWith(
                    fontWeight: FiftyTypography.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: FiftySpacing.sm),

                // Component + time badges row
                Wrap(
                  spacing: FiftySpacing.xs,
                  runSpacing: FiftySpacing.xs,
                  children: [
                    FiftyBadge(
                      label: event.component.toUpperCase(),
                      customColor: color,
                      showGlow: false,
                    ),
                    FiftyBadge(
                      label: FormatUtils.timeAgo(event.createdAt),
                      customColor: colorScheme.onSurfaceVariant,
                      showGlow: false,
                    ),
                  ],
                ),

                _buildDivider(colorScheme),

                // Info section
                _buildInfoRow(
                  context,
                  label: 'COMPONENT',
                  value: event.component,
                ),
                _buildInfoRow(
                  context,
                  label: 'PROJECT',
                  value: event.projectSlug,
                  onTap: event.projectSlug != null
                      ? () {
                          Navigator.of(context).pop();
                          Get.toNamed('/projects/${event.projectSlug}');
                        }
                      : null,
                ),
                _buildInfoRow(
                  context,
                  label: 'INSTANCE',
                  value: event.instanceId,
                  onTap: event.instanceId != null
                      ? () {
                          Navigator.of(context).pop();
                          Get.toNamed(AppRoutes.instances);
                        }
                      : null,
                ),
                _buildInfoRow(
                  context,
                  label: 'BRIEF',
                  value: event.briefId,
                  onTap: event.briefId != null && event.projectSlug != null
                      ? () {
                          Navigator.of(context).pop();
                          Get.toNamed('/projects/${event.projectSlug}');
                        }
                      : null,
                ),
                _buildInfoRow(
                  context,
                  label: 'TASK',
                  value: event.taskId,
                  onTap: event.taskId != null
                      ? () {
                          Navigator.of(context).pop();
                          Get.toNamed(AppRoutes.tasks);
                        }
                      : null,
                ),
                _buildInfoRow(
                  context,
                  label: 'HOSTNAME',
                  value: event.machineHostname,
                ),
                _buildInfoRow(
                  context,
                  label: 'TIMESTAMP',
                  value: _formatFullTimestamp(event.createdAt),
                ),

                _buildDivider(colorScheme),

                // Payload section
                Text(
                  'PAYLOAD',
                  style: textTheme.labelSmall!.copyWith(
                    fontWeight: FiftyTypography.bold,
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: FiftyTypography.letterSpacingLabel,
                  ),
                ),
                const SizedBox(height: FiftySpacing.sm),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(FiftySpacing.sm),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.5),
                    borderRadius: FiftyRadii.smRadius,
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: SelectableText(
                    _prettyPayload(event.payload),
                    style: ArenaTextStyles.mono(
                      context,
                      fontSize: 11,
                      fontWeight: FiftyTypography.regular,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                  ),
                ),

                // Context chips row
                if (event.hasContextLinks || event.projectSlug != null) ...[
                  const SizedBox(height: FiftySpacing.md),
                  EventContextChips(
                    event: event,
                    popBeforeNavigate: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a label-value info row with optional tap navigation.
  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    String? value,
    VoidCallback? onTap,
  }) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final valueWidget = Text(
      value,
      style: ArenaTextStyles.mono(
        context,
        fontSize: 11,
        fontWeight: FiftyTypography.semiBold,
        color: onTap != null ? colorScheme.primary : colorScheme.onSurface,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: FiftySpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: textTheme.labelSmall!.copyWith(
                fontWeight: FiftyTypography.medium,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                letterSpacing: FiftyTypography.letterSpacingLabel,
              ),
            ),
          ),
          Expanded(
            child: onTap != null
                ? GestureDetector(onTap: onTap, child: valueWidget)
                : valueWidget,
          ),
        ],
      ),
    );
  }

  /// Builds a themed divider.
  Widget _buildDivider(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FiftySpacing.sm),
      child: Divider(
        height: 1,
        color: colorScheme.outline.withValues(alpha: 0.3),
      ),
    );
  }

  /// Pretty-prints the event payload as formatted JSON.
  static String _prettyPayload(Map<String, dynamic> payload) {
    if (payload.isEmpty) return '{}';
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(payload);
    } catch (_) {
      return jsonEncode(payload);
    }
  }

  /// Formats the created_at timestamp as a full date-time string.
  static String _formatFullTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} '
          '${_pad(dt.hour)}:${_pad(dt.minute)}:${_pad(dt.second)}';
    } catch (_) {
      return timestamp;
    }
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
