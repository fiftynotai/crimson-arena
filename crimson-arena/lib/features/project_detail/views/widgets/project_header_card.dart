import 'package:fifty_theme/fifty_theme.dart';
import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:fifty_ui/fifty_ui.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/arena_text_styles.dart';
import '../../../../data/models/project_model.dart';
import '../../../../shared/widgets/arena_card.dart';

/// Header card for the Project Detail page.
///
/// Displays the project name (large), status badge, path (mono), and
/// tech stack. Handles null project gracefully.
class ProjectHeaderCard extends StatelessWidget {
  /// The project to display, or null if not yet loaded.
  final ProjectModel? project;

  const ProjectHeaderCard({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final ext = theme.extension<FiftyThemeExtension>()!;

    return ArenaCard(
      title: 'PROJECT',
      child: project == null
          ? Text(
              'Project not found',
              style: textTheme.bodySmall!.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Project name + status badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project!.name.isNotEmpty
                            ? project!.name
                            : project!.slug,
                        style: textTheme.titleMedium!.copyWith(
                          fontWeight: FiftyTypography.bold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: FiftySpacing.sm),
                    FiftyBadge(
                      label: project!.status.toUpperCase(),
                      variant: project!.status == 'active'
                          ? FiftyBadgeVariant.success
                          : FiftyBadgeVariant.neutral,
                      showGlow: project!.status == 'active',
                    ),
                  ],
                ),
                const SizedBox(height: FiftySpacing.sm),

                // Slug
                Row(
                  children: [
                    Text(
                      'SLUG',
                      style: textTheme.labelSmall!.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        letterSpacing:
                            FiftyTypography.letterSpacingLabelMedium,
                      ),
                    ),
                    const SizedBox(width: FiftySpacing.sm),
                    Expanded(
                      child: Text(
                        project!.slug,
                        style: ArenaTextStyles.mono(
                          context,
                          fontSize: 12,
                          fontWeight: FiftyTypography.medium,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: FiftySpacing.xs),

                // Path
                Row(
                  children: [
                    Text(
                      'PATH',
                      style: textTheme.labelSmall!.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        letterSpacing:
                            FiftyTypography.letterSpacingLabelMedium,
                      ),
                    ),
                    const SizedBox(width: FiftySpacing.sm),
                    Expanded(
                      child: Tooltip(
                        message: project!.path,
                        child: Text(
                          project!.path,
                          style: ArenaTextStyles.mono(
                            context,
                            fontSize: 11,
                            fontWeight: FiftyTypography.regular,
                            color: colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),

                // Tech stack
                if (project!.techStack != null &&
                    project!.techStack!.isNotEmpty) ...[
                  const SizedBox(height: FiftySpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: FiftySpacing.sm,
                      vertical: FiftySpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: ext.success.withValues(alpha: 0.08),
                      borderRadius: FiftyRadii.smRadius,
                      border: Border.all(
                        color: ext.success.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      project!.techStack!,
                      style: textTheme.labelSmall!.copyWith(
                        fontWeight: FiftyTypography.medium,
                        color: ext.success,
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
