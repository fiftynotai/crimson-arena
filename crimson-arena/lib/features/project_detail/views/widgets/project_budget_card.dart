import 'package:fifty_theme/fifty_theme.dart';
import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:fifty_ui/fifty_ui.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/arena_text_styles.dart';
import '../../../../data/models/project_budget_model.dart';
import '../../../../shared/utils/format_utils.dart';
import '../../../../shared/widgets/arena_card.dart';

/// Budget card for the Project Detail page.
///
/// Displays total cost, budget progress bar (when a limit is set),
/// per-agent cost breakdown, and token summary. Colors adapt to the
/// alert level returned by the API.
class ProjectBudgetCard extends StatelessWidget {
  /// The budget data to display.
  final ProjectBudgetModel budget;

  const ProjectBudgetCard({super.key, required this.budget});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final ext = theme.extension<FiftyThemeExtension>()!;
    final alertColor = _alertColor(budget.alertLevel, colorScheme, ext);

    return ArenaCard(
      title: 'BUDGET',
      trailing: FiftyBadge(
        label: budget.periodLabel.toUpperCase(),
        variant: FiftyBadgeVariant.neutral,
        showGlow: false,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total cost headline
          _buildCostHeadline(textTheme, alertColor),
          const SizedBox(height: FiftySpacing.sm),

          // Budget progress bar (if limit is set)
          if (budget.hasLimit) ...[
            _buildProgressBar(colorScheme, textTheme, alertColor),
            const SizedBox(height: FiftySpacing.sm),
          ] else ...[
            Text(
              'No budget limit set',
              style: textTheme.labelSmall!.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: FiftySpacing.sm),
          ],

          // Token summary
          _buildTokenSummary(context, colorScheme, textTheme),

          // Agent breakdown
          if (budget.byAgent.isNotEmpty) ...[
            const SizedBox(height: FiftySpacing.sm),
            _buildAgentBreakdown(context, colorScheme, textTheme, ext),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sub-builders
  // ---------------------------------------------------------------------------

  Widget _buildCostHeadline(TextTheme textTheme, Color alertColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          FormatUtils.formatCost(budget.totalCost),
          style: textTheme.headlineSmall!.copyWith(
            fontWeight: FiftyTypography.bold,
            color: alertColor,
          ),
        ),
        if (budget.hasLimit) ...[
          const SizedBox(width: FiftySpacing.xs),
          Text(
            'of ${FormatUtils.formatCost(budget.budgetLimit!)}',
            style: textTheme.bodySmall!.copyWith(
              color: alertColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressBar(
    ColorScheme colorScheme,
    TextTheme textTheme,
    Color alertColor,
  ) {
    final ratio = (budget.budgetRatio ?? 0).clamp(0.0, 1.0);
    final pct = budget.percentage.toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        ClipRRect(
          borderRadius: FiftyRadii.smRadius,
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(alertColor),
          ),
        ),
        const SizedBox(height: FiftySpacing.xs),
        // Label
        Text(
          '$pct% consumed',
          style: textTheme.labelSmall!.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTokenSummary(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        _tokenChip(
          context,
          'IN',
          FormatUtils.formatTokens(budget.totalInputTokens),
          colorScheme,
        ),
        const SizedBox(width: FiftySpacing.sm),
        _tokenChip(
          context,
          'OUT',
          FormatUtils.formatTokens(budget.totalOutputTokens),
          colorScheme,
        ),
        const SizedBox(width: FiftySpacing.sm),
        _tokenChip(
          context,
          'CACHE',
          FormatUtils.formatTokens(budget.totalCacheRead),
          colorScheme,
        ),
        const Spacer(),
        Text(
          '${budget.totalEventCount} events',
          style: textTheme.labelSmall!.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _tokenChip(
    BuildContext context,
    String label,
    String value,
    ColorScheme colorScheme,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: colorScheme.onSurfaceVariant,
                letterSpacing: FiftyTypography.letterSpacingLabelMedium,
              ),
        ),
        Text(
          value,
          style: ArenaTextStyles.mono(
            context,
            fontSize: 11,
            fontWeight: FiftyTypography.bold,
            color: colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildAgentBreakdown(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    FiftyThemeExtension ext,
  ) {
    // Sort agents by total cost descending.
    final sorted = List.of(budget.byAgent)
      ..sort((a, b) => b.totalCost.compareTo(a.totalCost));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AGENT COSTS',
          style: textTheme.labelSmall!.copyWith(
            color: colorScheme.onSurfaceVariant,
            letterSpacing: FiftyTypography.letterSpacingLabelMedium,
          ),
        ),
        const SizedBox(height: FiftySpacing.xs),
        ...sorted.map((agent) {
          return Padding(
            padding: const EdgeInsets.only(bottom: FiftySpacing.xs),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 12,
                  color:
                      colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                const SizedBox(width: FiftySpacing.xs),
                Expanded(
                  child: Text(
                    agent.agent,
                    style: textTheme.labelSmall!.copyWith(
                      fontWeight: FiftyTypography.medium,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: FiftySpacing.sm),
                Text(
                  FormatUtils.formatTokens(
                    agent.inputTokens + agent.outputTokens,
                  ),
                  style: ArenaTextStyles.mono(
                    context,
                    fontSize: 10,
                    fontWeight: FiftyTypography.medium,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: FiftySpacing.sm),
                Text(
                  FormatUtils.formatCost(agent.totalCost),
                  style: ArenaTextStyles.mono(
                    context,
                    fontSize: 11,
                    fontWeight: FiftyTypography.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Maps the API alert level to a theme-aware color.
  Color _alertColor(
    String? alertLevel,
    ColorScheme colorScheme,
    FiftyThemeExtension ext,
  ) {
    switch (alertLevel) {
      case 'critical':
        return colorScheme.error;
      case 'warning':
        return ext.warning;
      case 'normal':
        return ext.success;
      default:
        return colorScheme.onSurface;
    }
  }
}
