import 'package:crimson_arena/core/theme/arena_text_styles.dart';
import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:flutter/material.dart';

/// Displays horizontal bars showing the number of active tasks per agent.
///
/// Each bar consists of a fixed-width agent name label followed by a
/// colored bar segment proportional to the agent's task count. The bar
/// color uses crimson to match the dashboard theme.
class AgentWorkloadBar extends StatefulWidget {
  /// Map of agent name -> active task count.
  final Map<String, int> workload;

  const AgentWorkloadBar({super.key, required this.workload});

  @override
  State<AgentWorkloadBar> createState() => _AgentWorkloadBarState();
}

class _AgentWorkloadBarState extends State<AgentWorkloadBar> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: FiftyRadii.smRadius,
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header (tap to expand/collapse)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: FiftyRadii.smRadius,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FiftySpacing.sm,
                vertical: FiftySpacing.xs,
              ),
              child: Row(
                children: [
                  Text(
                    'AGENT WORKLOAD',
                    style: textTheme.labelSmall!.copyWith(
                      fontWeight: FiftyTypography.bold,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: FiftyTypography.letterSpacingLabel,
                    ),
                  ),
                  const SizedBox(width: FiftySpacing.xs),
                  Text(
                    '(${widget.workload.length} agents)',
                    style: textTheme.labelSmall!.copyWith(
                      fontWeight: FiftyTypography.medium,
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _isExpanded ? '[-]' : '[+]',
                    style: ArenaTextStyles.mono(
                      context,
                      fontSize: FiftyTypography.bodySmall,
                      fontWeight: FiftyTypography.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable body
          AnimatedSize(
            duration: FiftyMotion.compiling,
            curve: FiftyMotion.standard,
            alignment: Alignment.topCenter,
            child: _isExpanded ? _buildBody(context) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (widget.workload.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          FiftySpacing.sm,
          0,
          FiftySpacing.sm,
          FiftySpacing.sm,
        ),
        child: Text(
          'No agent assignments',
          style: textTheme.bodySmall!.copyWith(
            fontWeight: FiftyTypography.medium,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    // Sort agents by task count descending
    final sorted = widget.workload.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxCount =
        sorted.isNotEmpty ? sorted.first.value : 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FiftySpacing.sm,
        0,
        FiftySpacing.sm,
        FiftySpacing.sm,
      ),
      child: Column(
        children: sorted.map((entry) {
          final fraction = maxCount > 0 ? entry.value / maxCount : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: FiftySpacing.xs),
            child: Row(
              children: [
                // Agent name (fixed width)
                SizedBox(
                  width: 100,
                  child: Text(
                    entry.key.toUpperCase(),
                    style: ArenaTextStyles.mono(
                      context,
                      fontSize: FiftyTypography.labelSmall - 1,
                      fontWeight: FiftyTypography.semiBold,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: FiftySpacing.xs),

                // Bar
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final barWidth = constraints.maxWidth * fraction;

                      return Stack(
                        children: [
                          // Background track
                          Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.05),
                              borderRadius: FiftyRadii.smRadius,
                            ),
                          ),
                          // Filled bar
                          Container(
                            height: 14,
                            width: barWidth.clamp(0.0, constraints.maxWidth),
                            decoration: BoxDecoration(
                              color: const Color(0xFF960E29)
                                  .withValues(alpha: 0.7),
                              borderRadius: FiftyRadii.smRadius,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: FiftySpacing.xs),

                // Count label
                SizedBox(
                  width: 24,
                  child: Text(
                    '${entry.value}',
                    style: ArenaTextStyles.mono(
                      context,
                      fontSize: FiftyTypography.labelSmall - 1,
                      fontWeight: FiftyTypography.bold,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
