import 'dart:math';

import 'package:crimson_arena/core/constants/arena_colors.dart';
import 'package:crimson_arena/core/constants/arena_sizes.dart';
import 'package:crimson_arena/core/routing/app_routes.dart';
import 'package:crimson_arena/core/theme/arena_text_styles.dart';
import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:fifty_ui/fifty_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/models/task_model.dart';
import 'task_detail_modal.dart';

/// A single task card for the kanban board.
///
/// Displays the task title, type badge, priority indicator, assignee,
/// brief ID, and relative timestamp. Uses [FiftyCard] for consistent
/// hover effects and a colored left border to indicate priority level.
class TaskCard extends StatelessWidget {
  final TaskModel task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: FiftySpacing.sm),
      child: FiftyCard(
        onTap: () => TaskDetailModal.show(context, task),
        scanlineOnHover: true,
        hoverScale: 1.0,
        borderRadius: FiftyRadii.lgRadius,
        showShadow: false,
        padding: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(FiftySpacing.sm),
          child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        task.title,
                        style: textTheme.bodySmall!.copyWith(
                          fontWeight: FiftyTypography.semiBold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: FiftySpacing.xs),

                      // Type badge + priority dots + retry + effort row
                      Row(
                        children: [
                          // Task type badge
                          FiftyBadge(
                            label: task.taskType.toUpperCase(),
                            customColor: colorScheme.onSurfaceVariant,
                            showGlow: false,
                          ),
                          const SizedBox(width: FiftySpacing.xs),

                          // Effort estimate badge
                          if (_effort != null) ...[
                            FiftyBadge(
                              label: _effort!.toUpperCase(),
                              customColor: colorScheme.primary.withValues(
                                alpha: 0.7,
                              ),
                              showGlow: false,
                            ),
                            const SizedBox(width: FiftySpacing.xs),
                          ],

                          // Priority dots
                          _buildPriorityDots(context, task.priority),

                          // Retry count badge
                          if (task.retryCount > 0) ...[
                            const SizedBox(width: FiftySpacing.xs),
                            FiftyBadge(
                              label:
                                  'RETRY ${task.retryCount}/${task.maxRetries}',
                              variant: FiftyBadgeVariant.warning,
                              showGlow: false,
                            ),
                          ],

                          const Spacer(),

                          // Project slug (if available)
                          if (task.projectSlug != null &&
                              task.projectSlug!.isNotEmpty)
                            Text(
                              task.projectSlug!.toUpperCase(),
                              style: ArenaTextStyles.mono(
                                context,
                                fontSize: ArenaSizes.monoFontSizeMicro,
                                fontWeight: FiftyTypography.medium,
                                color: colorScheme.primary.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: FiftySpacing.xs),

                      // Bottom row: assignee + brief + time
                      Row(
                        children: [
                          // Assignee
                          if (task.assignee != null &&
                              task.assignee!.isNotEmpty) ...[
                            Icon(
                              Icons.person_outline,
                              size: 12,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: ArenaSizes.microGap),
                            Text(
                              task.assignee!,
                              style: textTheme.labelSmall!.copyWith(
                                fontWeight: FiftyTypography.medium,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: FiftySpacing.sm),
                          ],

                          // Brief ID (clickable)
                          if (task.briefId != null &&
                              task.briefId!.isNotEmpty) ...[
                            GestureDetector(
                              onTap: task.projectSlug != null
                                  ? () => Get.toNamed(
                                        '/projects/${task.projectSlug}',
                                      )
                                  : null,
                              child: Text(
                                task.briefId!,
                                style: ArenaTextStyles.mono(
                                  context,
                                  fontSize: ArenaSizes.monoFontSizeMicro,
                                  fontWeight: FiftyTypography.semiBold,
                                  color: task.projectSlug != null
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                            const SizedBox(width: FiftySpacing.sm),
                          ],

                          // Instance ID (clickable)
                          if (_instanceId != null) ...[
                            GestureDetector(
                              onTap: () =>
                                  Get.toNamed(AppRoutes.instances),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.dns_outlined,
                                    size: 10,
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: ArenaSizes.microGap),
                                  Text(
                                    _instanceId!.substring(
                                      0,
                                      min(8, _instanceId!.length),
                                    ),
                                    style: ArenaTextStyles.mono(
                                      context,
                                      fontSize: ArenaSizes.monoFontSizeMicro,
                                      fontWeight: FiftyTypography.medium,
                                      color: colorScheme.primary
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: FiftySpacing.sm),
                          ],

                          const Spacer(),

                          // Relative time
                          Text(
                            _relativeTime(task.updatedAt),
                            style: ArenaTextStyles.mono(
                              context,
                              fontSize: ArenaSizes.monoFontSizeMicro,
                              fontWeight: FiftyTypography.medium,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),

                      // Fail reason (if failed)
                      if (task.failReason != null &&
                          task.failReason!.isNotEmpty) ...[
                        const SizedBox(height: FiftySpacing.xs),
                        Text(
                          task.failReason!,
                          style: textTheme.labelSmall!.copyWith(
                            fontWeight: FiftyTypography.medium,
                            color: ArenaColors.taskFailed.withValues(
                              alpha: 0.8,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }

  /// Instance ID extracted from task metadata.
  String? get _instanceId => task.metadata['instance_id'] as String?;

  /// Effort estimate extracted from task metadata.
  String? get _effort {
    final e = task.metadata['effort'] as String?;
    return (e != null && e.isNotEmpty) ? e : null;
  }

  Widget _buildPriorityDots(BuildContext context, int priority) {
    final color = ArenaColors.taskPriorityColor(priority);
    const totalDots = 5;
    // Priority 1 = most urgent = 5 filled dots
    // Priority 5 = least urgent = 1 filled dot
    final filledDots = (totalDots - priority + 1).clamp(1, totalDots);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalDots, (i) {
        final filled = i < filledDots;
        return Container(
          width: 4,
          height: 4,
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

  /// Convert ISO timestamp to relative time string.
  String _relativeTime(String timestamp) {
    if (timestamp.isEmpty) return '--';
    final dt = DateTime.tryParse(timestamp);
    if (dt == null) return '--';

    final diff = DateTime.now().toUtc().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
