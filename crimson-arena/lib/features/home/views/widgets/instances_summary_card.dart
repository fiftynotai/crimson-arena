import 'package:fifty_theme/fifty_theme.dart';
import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/arena_card.dart';
import '../../controllers/home_view_model.dart';

/// Summary card showing active, idle, and total instance counts.
///
/// Tapping the card navigates to the Instances page for full details.
class InstancesSummaryCard extends StatelessWidget {
  const InstancesSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Get.find<HomeViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final ext = theme.extension<FiftyThemeExtension>()!;

    return Obx(() {
      final all = vm.instances;
      final active = all.where((i) => i.status == 'active').length;
      final idle = all.length - active;

      return ArenaCard(
        title: 'INSTANCES',
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 12,
          color: colorScheme.onSurfaceVariant,
        ),
        onTap: () => Get.toNamed(AppRoutes.instances),
        child: Row(
          children: [
            _StatChip(
              label: 'Active',
              value: '$active',
              color: ext.success,
              textTheme: textTheme,
            ),
            const SizedBox(width: FiftySpacing.md),
            _StatChip(
              label: 'Idle',
              value: '$idle',
              color: colorScheme.onSurfaceVariant,
              textTheme: textTheme,
            ),
            const SizedBox(width: FiftySpacing.md),
            _StatChip(
              label: 'Total',
              value: '${all.length}',
              color: colorScheme.onSurface,
              textTheme: textTheme,
            ),
          ],
        ),
      );
    });
  }
}

/// A compact stat display: large value above a small label.
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final TextTheme textTheme;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: textTheme.headlineSmall!.copyWith(
            fontWeight: FiftyTypography.extraBold,
            color: color,
          ),
        ),
        Text(
          label,
          style: textTheme.labelSmall!.copyWith(
            color: color.withValues(alpha: 0.7),
            letterSpacing: FiftyTypography.letterSpacingLabel,
          ),
        ),
      ],
    );
  }
}
