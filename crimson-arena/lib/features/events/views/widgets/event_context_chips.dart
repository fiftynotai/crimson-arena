import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/arena_text_styles.dart';
import '../../../../data/models/brain_event_model.dart';
import '../../../../shared/widgets/arena_hover_button.dart';

/// Displays tappable context chips for navigable fields on a [BrainEventModel].
///
/// Shows small labeled chips for INSTANCE, TASK, BRIEF, and PROJECT when
/// the corresponding value is non-null. Tapping a chip navigates to the
/// relevant page.
class EventContextChips extends StatelessWidget {
  /// The event whose context links to render.
  final BrainEventModel event;

  /// Whether to close an enclosing dialog before navigating.
  final bool popBeforeNavigate;

  const EventContextChips({
    super.key,
    required this.event,
    this.popBeforeNavigate = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!event.hasContextLinks && event.projectSlug == null) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: FiftySpacing.xs,
      runSpacing: FiftySpacing.xs,
      children: [
        if (event.instanceId != null)
          _ContextChip(
            icon: Icons.dns_outlined,
            label: _truncate(event.instanceId!, 8),
            color: const Color(0xFFFBBF24), // yellow, matches instances
            onTap: () => _navigate(context, AppRoutes.instances),
          ),
        if (event.taskId != null)
          _ContextChip(
            icon: Icons.task_alt_outlined,
            label: _truncate(event.taskId!, 8),
            color: const Color(0xFFA78BFA), // purple, matches tasks
            onTap: () => _navigate(context, AppRoutes.tasks),
          ),
        if (event.briefId != null)
          _ContextChip(
            icon: Icons.description_outlined,
            label: _truncate(event.briefId!, 12),
            color: const Color(0xFFE879F9), // fuchsia, matches briefs
            onTap: event.projectSlug != null
                ? () => _navigate(
                      context,
                      '/projects/${event.projectSlug}',
                    )
                : null,
          ),
        if (event.projectSlug != null)
          _ContextChip(
            icon: Icons.folder_outlined,
            label: event.projectSlug!,
            color: const Color(0xFF818CF8), // indigo, matches projects
            onTap: () => _navigate(
              context,
              '/projects/${event.projectSlug}',
            ),
          ),
      ],
    );
  }

  void _navigate(BuildContext context, String route) {
    if (popBeforeNavigate) {
      Navigator.of(context).pop();
    }
    Get.toNamed(route);
  }

  static String _truncate(String value, int maxLen) {
    if (value.length <= maxLen) return value;
    return '${value.substring(0, maxLen)}...';
  }
}

/// A single small tappable chip showing an icon and truncated label.
class _ContextChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ContextChip({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ArenaHoverButton(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: ArenaTextStyles.mono(
              context,
              fontSize: 10,
              fontWeight: FiftyTypography.semiBold,
              color: onTap != null
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
