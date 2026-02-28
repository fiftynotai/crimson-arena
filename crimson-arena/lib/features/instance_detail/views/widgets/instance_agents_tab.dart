import 'package:crimson_arena/core/theme/arena_text_styles.dart';
import 'package:fifty_theme/fifty_theme.dart';
import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/agent_constants.dart';
import '../../../../data/models/agent_nexus_entry.dart';
import '../../../instances/views/widgets/agent_nexus_table.dart';
import '../../controllers/instance_detail_view_model.dart';

/// Agents tab for the Instance Detail page.
///
/// Reuses [AgentNexusTable] and adds per-agent summary stats below it.
class InstanceAgentsTab extends StatelessWidget {
  final InstanceDetailViewModel vm;

  const InstanceAgentsTab({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final instance = vm.instance.value;
      if (instance == null) return const SizedBox.shrink();

      final agents = vm.nexusData.toList();

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: FiftySpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Agent nexus table
            AgentNexusTable(
              instanceId: instance.id,
              nexusData: agents,
            ),
            const SizedBox(height: FiftySpacing.md),

            // Per-agent detail cards
            if (agents.isNotEmpty) _buildAgentDetails(context, agents),
          ],
        ),
      );
    });
  }

  Widget _buildAgentDetails(
    BuildContext context,
    List<AgentNexusEntry> agents,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Only show agents that have been active.
    final activeAgents = agents.where((a) => a.eventCount > 0).toList();
    if (activeAgents.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(FiftySpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: FiftyRadii.smRadius,
        border: Border.all(
          color: colorScheme.outline,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AGENT STATS',
            style: textTheme.labelMedium!.copyWith(
              color: colorScheme.onSurfaceVariant,
              letterSpacing: FiftyTypography.letterSpacingLabelMedium,
            ),
          ),
          const SizedBox(height: FiftySpacing.sm),
          Wrap(
            spacing: FiftySpacing.sm,
            runSpacing: FiftySpacing.sm,
            children: activeAgents
                .map((a) => _buildAgentCard(context, a))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentCard(BuildContext context, AgentNexusEntry agent) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ext = theme.extension<FiftyThemeExtension>()!;
    final textTheme = theme.textTheme;
    final agentColor = Color(
      AgentConstants.agentColors[agent.agent] ?? 0xFF888888,
    );
    final status = agent.status ?? 'IDLE';

    Color statusColor;
    switch (status.toUpperCase()) {
      case 'WORKING':
        statusColor = ext.warning;
      case 'DONE':
        statusColor = ext.success;
      case 'FAIL':
        statusColor = colorScheme.primary;
      default:
        statusColor = colorScheme.onSurfaceVariant;
    }

    return Container(
      width: 200,
      padding: const EdgeInsets.all(FiftySpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: FiftyRadii.smRadius,
        border: Border.all(
          color: colorScheme.outline,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Agent name + status
          Row(
            children: [
              Text(
                (AgentConstants.agentNames[agent.agent] ?? agent.agent)
                    .toUpperCase(),
                style: textTheme.labelSmall!.copyWith(
                  fontWeight: FiftyTypography.bold,
                  color: agentColor,
                  letterSpacing: FiftyTypography.letterSpacingLabelMedium,
                ),
              ),
              const Spacer(),
              Text(
                status,
                style: textTheme.labelSmall!.copyWith(
                  fontWeight: FiftyTypography.bold,
                  color: statusColor,
                  letterSpacing: FiftyTypography.letterSpacingLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: FiftySpacing.xs),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _statItem(
                  context,
                  'TIME',
                  agent.formattedDuration,
                ),
              ),
              Expanded(
                child: _statItem(
                  context,
                  'TOKENS',
                  _formatTokens(agent.totalTokens),
                ),
              ),
              Expanded(
                child: _statItem(
                  context,
                  'EVENTS',
                  '${agent.eventCount}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: textTheme.labelSmall!.copyWith(
            color: colorScheme.onSurfaceVariant,
            letterSpacing: FiftyTypography.letterSpacingLabel,
            fontSize: 9,
          ),
        ),
        Text(
          value,
          style: ArenaTextStyles.mono(
            context,
            fontSize: FiftyTypography.labelSmall,
            fontWeight: FiftyTypography.medium,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  String _formatTokens(int tokens) {
    if (tokens == 0) return '0';
    if (tokens < 1000) return '$tokens';
    if (tokens < 1000000) return '${(tokens / 1000).toStringAsFixed(1)}K';
    return '${(tokens / 1000000).toStringAsFixed(1)}M';
  }
}
