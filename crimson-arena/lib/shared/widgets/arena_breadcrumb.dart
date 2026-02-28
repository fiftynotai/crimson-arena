import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A single segment in the breadcrumb trail.
///
/// When [route] is non-null the segment is clickable and navigates on tap.
/// When [route] is null the segment is the terminal (current) page and is
/// rendered in bold without interaction.
class BreadcrumbSegment {
  /// Display text for this segment.
  final String label;

  /// Named route to navigate to on tap, or `null` for the terminal segment.
  final String? route;

  const BreadcrumbSegment({required this.label, this.route});
}

/// Horizontal breadcrumb trail rendered below the [ArenaScaffold] nav bar.
///
/// Segments are separated by ` / ` dividers. Clickable segments navigate via
/// [Get.offNamed] and terminal segments are displayed in bold.
class ArenaBreadcrumb extends StatelessWidget {
  /// Ordered list of breadcrumb segments from root to current page.
  final List<BreadcrumbSegment> segments;

  const ArenaBreadcrumb({super.key, required this.segments});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final children = <Widget>[];

    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final isTerminal = segment.route == null;

      // Build the label text widget.
      final displayLabel =
          isTerminal ? segment.label : segment.label.toUpperCase();

      final labelWidget = Text(
        displayLabel,
        overflow: TextOverflow.ellipsis,
        style: textTheme.labelSmall!.copyWith(
          fontWeight:
              isTerminal ? FiftyTypography.bold : FiftyTypography.medium,
          color: isTerminal
              ? colorScheme.onSurface
              : colorScheme.onSurfaceVariant,
        ),
      );

      if (isTerminal) {
        children.add(Flexible(child: labelWidget));
      } else {
        children.add(
          Flexible(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => Get.offNamed(segment.route!),
                child: labelWidget,
              ),
            ),
          ),
        );
      }

      // Add separator between segments.
      if (i < segments.length - 1) {
        children.add(
          Text(
            ' / ',
            style: textTheme.labelSmall!.copyWith(
              color: colorScheme.outline,
            ),
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FiftySpacing.lg,
        vertical: FiftySpacing.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}
