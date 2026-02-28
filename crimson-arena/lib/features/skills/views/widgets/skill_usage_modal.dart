import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:fifty_ui/fifty_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/arena_colors.dart';
import '../../../../core/constants/skill_constants.dart';
import '../../../../core/theme/arena_text_styles.dart';
import '../../../../data/models/skill_card_model.dart';
import '../../../../shared/utils/format_utils.dart';
import '../../controllers/skills_view_model.dart';

/// A detail modal for inspecting recent invocations of a single skill.
///
/// Follows the same structural pattern as [TaskDetailModal]:
/// transparent Dialog > ConstrainedBox > surfaceContainerHighest container.
///
/// Displays:
/// - Header: skill name + rarity badge + category badge
/// - Invocation count + usage bar
/// - "RECENT INVOCATIONS" list with timestamps
/// - Loading / empty states
class SkillUsageModal extends StatelessWidget {
  /// The ViewModel that owns the usage drill-down state.
  final SkillsViewModel vm;

  /// The skill card model for static metadata (name, rarity, category).
  final SkillCardModel skill;

  const SkillUsageModal({
    super.key,
    required this.vm,
    required this.skill,
  });

  /// Shows the [SkillUsageModal] as a centered dialog.
  static void show(
    BuildContext context,
    SkillsViewModel vm,
    SkillCardModel skill,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => SkillUsageModal(vm: vm, skill: skill),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final categoryColor =
        SkillConstants.categoryColorMap[skill.category] ??
            ArenaColors.categorySystem;
    final rarityColor = _rarityColor(skill.rarity);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
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
                // Header row: label + close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SKILL USAGE',
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

                // Skill name
                Text(
                  '/${skill.name}'.toUpperCase(),
                  style: ArenaTextStyles.mono(
                    context,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: FiftySpacing.xs),

                // Description
                Text(
                  skill.description,
                  style: textTheme.bodySmall!.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: FiftySpacing.sm),

                // Badges row: category + rarity
                Wrap(
                  spacing: FiftySpacing.xs,
                  runSpacing: FiftySpacing.xs,
                  children: [
                    FiftyBadge(
                      label: skill.category.name.toUpperCase(),
                      customColor: categoryColor,
                      showGlow: false,
                    ),
                    FiftyBadge(
                      label: skill.rarity.displayName.toUpperCase(),
                      customColor: rarityColor,
                      showGlow: false,
                    ),
                  ],
                ),

                _buildDivider(colorScheme),

                // Invocation count
                Obx(() {
                  final total = vm.selectedSkillTotal.value;
                  return _buildInfoRow(
                    context,
                    label: 'INVOCATIONS',
                    value: FormatUtils.formatNumber(total),
                  );
                }),
                const SizedBox(height: FiftySpacing.xs),

                // Usage bar
                _buildUsageBar(context, categoryColor),

                _buildDivider(colorScheme),

                // Recent invocations section
                Text(
                  'RECENT INVOCATIONS',
                  style: textTheme.labelSmall!.copyWith(
                    fontWeight: FiftyTypography.bold,
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: FiftyTypography.letterSpacingLabel,
                  ),
                ),
                const SizedBox(height: FiftySpacing.sm),

                // Content: loading, empty, or list
                Obx(() {
                  if (vm.isLoadingUsage.value) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: FiftySpacing.lg),
                      child: Center(
                        child: FiftyLoadingIndicator(
                          style: FiftyLoadingStyle.sequence,
                          size: FiftyLoadingSize.medium,
                          sequences: [
                            '> LOADING INVOCATIONS...',
                            '> RESOLVING TIMESTAMPS...',
                          ],
                        ),
                      ),
                    );
                  }

                  final usageList = vm.selectedSkillUsage;
                  if (usageList.isEmpty) {
                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: FiftySpacing.md),
                      child: Text(
                        'No invocations recorded',
                        style: textTheme.bodySmall!.copyWith(
                          color:
                              colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: usageList.map((usage) {
                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: FiftySpacing.xs),
                        child: Row(
                          children: [
                            // Timestamp
                            Expanded(
                              child: Text(
                                FormatUtils.timeAgo(usage.ts),
                                style: ArenaTextStyles.mono(
                                  context,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            // Session date
                            Text(
                              usage.sessionDate,
                              style: ArenaTextStyles.mono(
                                context,
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                            // Project slug (if present)
                            if (usage.projectSlug.isNotEmpty) ...[
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
                                  usage.projectSlug,
                                  style: textTheme.labelSmall!.copyWith(
                                    fontSize: 10,
                                    fontWeight: FiftyTypography.medium,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a label-value info row.
  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.labelSmall!.copyWith(
            fontWeight: FiftyTypography.medium,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
            letterSpacing: FiftyTypography.letterSpacingLabelMedium,
          ),
        ),
        Text(
          value,
          style: ArenaTextStyles.mono(
            context,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  /// Builds the usage bar showing relative usage for this skill.
  Widget _buildUsageBar(BuildContext context, Color categoryColor) {
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(() {
      final maxInvocations = vm.skillHeatmapTotal.value;
      final total = vm.selectedSkillTotal.value;
      final progress = maxInvocations > 0
          ? (total / maxInvocations).clamp(0.0, 1.0)
          : 0.0;

      return SizedBox(
        height: 4,
        child: ClipRRect(
          borderRadius: FiftyRadii.smRadius,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: colorScheme.onSurface.withValues(alpha: 0.05),
            valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
          ),
        ),
      );
    });
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

  /// Map [SkillRarity] to a glow/border color matching the rarity theme.
  Color _rarityColor(SkillRarity rarity) {
    switch (rarity) {
      case SkillRarity.common:
        return FiftyColors.slateGrey;
      case SkillRarity.uncommon:
        return FiftyColors.hunterGreen;
      case SkillRarity.rare:
        return FiftyColors.powderBlush;
      case SkillRarity.epic:
        return FiftyColors.burgundy;
      case SkillRarity.legendary:
        return ArenaColors.legendaryGold;
    }
  }
}
