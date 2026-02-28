import 'package:crimson_arena/core/constants/arena_colors.dart';
import 'package:crimson_arena/core/constants/arena_sizes.dart';
import 'package:crimson_arena/core/routing/app_routes.dart';
import 'package:crimson_arena/core/theme/arena_text_styles.dart';
import 'package:crimson_arena/shared/utils/format_utils.dart';
import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:fifty_ui/fifty_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/models/task_model.dart';

/// A detail modal dialog for inspecting a single task.
///
/// Displays all task fields in a structured layout: title, status/priority
/// badges, linked brief/instance/project, description, and metadata such
/// as retry count, effort estimate, timestamps, and failure reason.
class TaskDetailModal extends StatelessWidget {
  /// The task to display in detail.
  final TaskModel task;

  const TaskDetailModal({super.key, required this.task});

  /// Shows the [TaskDetailModal] as a centered dialog.
  static void show(BuildContext context, TaskModel task) {
    showDialog<void>(
      context: context,
      builder: (_) => TaskDetailModal(task: task),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
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
                      'TASK DETAIL',
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

                // Title
                Text(
                  task.title,
                  style: textTheme.titleMedium!.copyWith(
                    fontWeight: FiftyTypography.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: FiftySpacing.sm),

                // Status + Priority + Type badges row
                Wrap(
                  spacing: FiftySpacing.xs,
                  runSpacing: FiftySpacing.xs,
                  children: [
                    FiftyBadge(
                      label: task.status.toUpperCase(),
                      customColor: ArenaColors.taskStatusColor(task.status),
                      showGlow: task.isActive,
                    ),
                    _buildPriorityDots(context, task.priority),
                    FiftyBadge(
                      label: task.taskType.toUpperCase(),
                      customColor: colorScheme.onSurfaceVariant,
                      showGlow: false,
                    ),
                  ],
                ),

                _buildDivider(colorScheme),

                // Info section
                _buildInfoRow(
                  context,
                  label: 'BRIEF',
                  value: task.briefId,
                  onTap: task.briefId != null && task.projectSlug != null
                      ? () {
                          Navigator.of(context).pop();
                          Get.toNamed(
                            '/projects/${task.projectSlug}',
                          );
                        }
                      : null,
                ),
                _buildInfoRow(
                  context,
                  label: 'INSTANCE',
                  value: _instanceId,
                  onTap: _instanceId != null
                      ? () {
                          Navigator.of(context).pop();
                          Get.toNamed(AppRoutes.instances);
                        }
                      : null,
                ),
                _buildInfoRow(
                  context,
                  label: 'PROJECT',
                  value: task.projectSlug,
                  onTap: task.projectSlug != null
                      ? () {
                          Navigator.of(context).pop();
                          Get.toNamed(
                            '/projects/${task.projectSlug}',
                          );
                        }
                      : null,
                ),
                _buildInfoRow(context, label: 'ASSIGNEE', value: task.assignee),
                _buildInfoRow(context, label: 'SCOPE', value: task.scope),

                // Description
                if (task.description != null &&
                    task.description!.isNotEmpty) ...[
                  _buildDivider(colorScheme),
                  Text(
                    'DESCRIPTION',
                    style: textTheme.labelSmall!.copyWith(
                      fontWeight: FiftyTypography.bold,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: FiftyTypography.letterSpacingLabel,
                    ),
                  ),
                  const SizedBox(height: FiftySpacing.xs),
                  Text(
                    task.description!,
                    style: textTheme.bodySmall!.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],

                _buildDivider(colorScheme),

                // Meta section
                if (task.retryCount > 0)
                  _buildInfoRow(
                    context,
                    label: 'RETRY',
                    value: '${task.retryCount}/${task.maxRetries}',
                  ),
                if (_effort != null)
                  _buildInfoRow(
                    context,
                    label: 'EFFORT',
                    value: _effort!.toUpperCase(),
                  ),
                _buildInfoRow(
                  context,
                  label: 'CREATED BY',
                  value: task.createdBy,
                ),
                _buildInfoRow(
                  context,
                  label: 'CREATED',
                  value: FormatUtils.timeAgo(task.createdAt),
                ),
                _buildInfoRow(
                  context,
                  label: 'UPDATED',
                  value: FormatUtils.timeAgo(task.updatedAt),
                ),
                if (task.failReason != null &&
                    task.failReason!.isNotEmpty) ...[
                  const SizedBox(height: FiftySpacing.xs),
                  _buildInfoRow(
                    context,
                    label: 'FAIL REASON',
                    value: task.failReason,
                    valueColor: ArenaColors.taskFailed,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Instance ID extracted from metadata.
  String? get _instanceId => task.metadata['instance_id'] as String?;

  /// Effort estimate extracted from metadata.
  String? get _effort {
    final e = task.metadata['effort'] as String?;
    return (e != null && e.isNotEmpty) ? e : null;
  }

  /// Builds a label-value info row with optional tap navigation.
  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    String? value,
    VoidCallback? onTap,
    Color? valueColor,
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
        color: onTap != null
            ? colorScheme.primary
            : valueColor ?? colorScheme.onSurface,
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

  /// Builds the priority dots indicator.
  Widget _buildPriorityDots(BuildContext context, int priority) {
    final color = ArenaColors.taskPriorityColor(priority);
    const totalDots = 5;
    final filledDots = (totalDots - priority + 1).clamp(1, totalDots);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalDots, (i) {
        final filled = i < filledDots;
        return Container(
          width: 5,
          height: 5,
          margin: EdgeInsets.only(
            right: i < totalDots - 1 ? ArenaSizes.microGap : 0,
          ),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? color : color.withValues(alpha: 0.2),
          ),
        );
      }),
    );
  }
}
