import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../instances/views/widgets/execution_log_widget.dart';
import '../../../instances/views/widgets/hunt_pipeline_widget.dart';
import '../../../instances/views/widgets/team_mode_widget.dart';
import '../../controllers/instance_detail_view_model.dart';

/// Hunt tab for the Instance Detail page.
///
/// Reuses [HuntPipelineWidget], [ExecutionLogWidget], and [TeamModeWidget]
/// from the instances feature, passing data from the detail ViewModel.
class InstanceHuntTab extends StatelessWidget {
  final InstanceDetailViewModel vm;

  const InstanceHuntTab({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final instance = vm.instance.value;
      if (instance == null) return const SizedBox.shrink();

      final logEntries = vm.executionLogs.toList();
      final retries = vm.retryCount.value;
      final teamData = vm.teamStatus.value;
      final isTeamLead = teamData != null && teamData.active;

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: FiftySpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hunt pipeline
            HuntPipelineWidget(instance: instance),
            const SizedBox(height: FiftySpacing.md),

            // Execution log
            ExecutionLogWidget(
              instanceId: instance.id,
              entries: logEntries,
              retryCount: retries,
            ),

            // Team mode (if team lead)
            if (isTeamLead) ...[
              const SizedBox(height: FiftySpacing.md),
              TeamModeWidget(teamStatus: teamData),
            ],
          ],
        ),
      );
    });
  }
}
