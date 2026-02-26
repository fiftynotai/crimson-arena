import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/project_selector_service.dart';

/// Compact project selector dropdown for the nav bar.
///
/// Reads from [ProjectSelectorService] and displays the currently selected
/// project name (or "ALL PROJECTS"). Tapping opens a popup menu to switch
/// projects or select "All Projects".
///
/// Styling matches the FDL v2 dark theme tokens used by [ArenaScaffold].
class ProjectSelectorDropdown extends StatelessWidget {
  /// When true, shows abbreviated slug instead of full project name.
  final bool compact;

  const ProjectSelectorDropdown({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final service = Get.find<ProjectSelectorService>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Obx(() {
      final selected = service.selectedProject;
      final label = compact
          ? (selected?.slug.toUpperCase() ?? 'ALL')
          : (selected?.name.toUpperCase() ?? 'ALL PROJECTS');

      return PopupMenuButton<String?>(
        tooltip: 'Select project',
        offset: const Offset(0, 40),
        color: colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: FiftyRadii.smRadius,
          side: BorderSide(color: colorScheme.outline, width: 1),
        ),
        onSelected: service.selectProject,
        itemBuilder: (_) => _buildMenuItems(context, service),
        child: Container(
          height: 32,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? FiftySpacing.sm : FiftySpacing.md,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: FiftyRadii.smRadius,
            border: Border.all(
              color: selected != null
                  ? colorScheme.primary.withValues(alpha: 0.4)
                  : colorScheme.outline,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_outlined,
                size: 14,
                color: selected != null
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: FiftySpacing.xs),
              Text(
                label,
                style: textTheme.labelSmall!.copyWith(
                  fontWeight: FiftyTypography.bold,
                  color: selected != null
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  letterSpacing: FiftyTypography.letterSpacingLabelMedium,
                ),
              ),
              const SizedBox(width: FiftySpacing.xs),
              Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      );
    });
  }

  List<PopupMenuEntry<String?>> _buildMenuItems(
    BuildContext context,
    ProjectSelectorService service,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final currentSlug = service.selectedProjectSlug.value;

    final items = <PopupMenuEntry<String?>>[];

    // "ALL PROJECTS" option
    items.add(
      PopupMenuItem<String?>(
        value: null,
        child: Row(
          children: [
            Icon(
              Icons.apps,
              size: 16,
              color: currentSlug == null
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: FiftySpacing.sm),
            Text(
              'ALL PROJECTS',
              style: textTheme.labelMedium!.copyWith(
                fontWeight: currentSlug == null
                    ? FiftyTypography.bold
                    : FiftyTypography.medium,
                color: currentSlug == null
                    ? colorScheme.primary
                    : colorScheme.onSurface,
                letterSpacing: FiftyTypography.letterSpacingLabelMedium,
              ),
            ),
          ],
        ),
      ),
    );

    if (service.projects.isNotEmpty) {
      items.add(const PopupMenuDivider(height: 1));
    }

    // Individual project options
    for (final project in service.projects) {
      final isSelected = currentSlug == project.slug;
      items.add(
        PopupMenuItem<String?>(
          value: project.slug,
          child: Row(
            children: [
              Icon(
                Icons.folder_outlined,
                size: 16,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: FiftySpacing.sm),
              Expanded(
                child: Text(
                  project.name.toUpperCase(),
                  style: textTheme.labelMedium!.copyWith(
                    fontWeight: isSelected
                        ? FiftyTypography.bold
                        : FiftyTypography.medium,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    letterSpacing: FiftyTypography.letterSpacingLabelMedium,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (project.techStack != null) ...[
                const SizedBox(width: FiftySpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FiftySpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: FiftyRadii.smRadius,
                  ),
                  child: Text(
                    project.techStack!,
                    style: textTheme.labelSmall!.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return items;
  }
}
