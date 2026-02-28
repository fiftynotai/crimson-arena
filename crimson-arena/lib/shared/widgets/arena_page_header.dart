import 'package:crimson_arena/core/theme/arena_text_styles.dart';
import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/project_selector_service.dart';
import 'arena_hover_button.dart';

/// Unified page header shown at the top of every dashboard page.
///
/// Provides a consistent title row with optional project context, a count
/// badge, a refresh button, and arbitrary trailing actions.
///
/// ```
/// [TITLE]  (project-name)  [count badge]                 [REFRESH] [actions...]
/// ```
class ArenaPageHeader extends StatelessWidget {
  /// Page title, displayed uppercase.
  final String title;

  /// Count/summary text shown in a primary-tinted pill (e.g. "45 tasks").
  /// Hidden when `null`.
  final String? summary;

  /// Refresh callback. The REFRESH button is hidden when `null`.
  final VoidCallback? onRefresh;

  /// Additional action widgets rendered after the refresh button.
  final List<Widget>? actions;

  /// Horizontal padding applied to the row. Defaults to [FiftySpacing.lg].
  final double horizontalPadding;

  const ArenaPageHeader({
    super.key,
    required this.title,
    this.summary,
    this.onRefresh,
    this.actions,
    this.horizontalPadding = FiftySpacing.lg,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: FiftySpacing.sm,
      ),
      child: Row(
        children: [
          // Title
          Text(
            title.toUpperCase(),
            style: textTheme.titleSmall!.copyWith(
              fontWeight: FiftyTypography.extraBold,
              color: colorScheme.onSurface,
              letterSpacing: FiftyTypography.letterSpacingLabelMedium,
            ),
          ),

          // Project context (reactive)
          Obx(() {
            final project =
                Get.find<ProjectSelectorService>().selectedProject;
            if (project == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(left: FiftySpacing.sm),
              child: Text(
                '(${project.name})',
                style: textTheme.titleSmall!.copyWith(
                  fontWeight: FiftyTypography.medium,
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: FiftyTypography.letterSpacingLabelMedium,
                ),
              ),
            );
          }),

          // Count badge
          if (summary != null) ...[
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
                summary!,
                style: ArenaTextStyles.mono(
                  context,
                  fontSize: FiftyTypography.labelSmall,
                  fontWeight: FiftyTypography.semiBold,
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],

          const Spacer(),

          // Refresh button
          if (onRefresh != null)
            ArenaHoverButton(
              onTap: onRefresh,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: FiftySpacing.xs),
                  Text(
                    'REFRESH',
                    style: textTheme.labelSmall!.copyWith(
                      fontWeight: FiftyTypography.bold,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: FiftyTypography.letterSpacingLabelMedium,
                    ),
                  ),
                ],
              ),
            ),

          // Additional actions
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
