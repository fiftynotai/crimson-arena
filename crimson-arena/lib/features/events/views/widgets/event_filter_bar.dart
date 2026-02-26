import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/arena_text_styles.dart';
import '../../controllers/events_view_model.dart';
import 'live_event_card.dart';

/// Filter bar for the events page.
///
/// Contains toggleable component filter chips (color-coded), a search
/// text field, and a clear-all button.
class EventFilterBar extends StatefulWidget {
  const EventFilterBar({super.key});

  @override
  State<EventFilterBar> createState() => _EventFilterBarState();
}

class _EventFilterBarState extends State<EventFilterBar> {
  final _searchController = TextEditingController();
  final _vm = Get.find<EventsViewModel>();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _vm.setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FiftySpacing.md,
        vertical: FiftySpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: FiftyRadii.mdRadius,
        border: Border.all(
          color: colorScheme.outline,
          width: 1,
        ),
      ),
      child: Wrap(
        spacing: FiftySpacing.xs,
        runSpacing: FiftySpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Label
          Text(
            'FILTER:',
            style: textTheme.labelSmall!.copyWith(
              fontWeight: FiftyTypography.bold,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: FiftyTypography.letterSpacingLabel,
            ),
          ),

          // Component chips
          ..._vm.components.map((component) {
            return Obx(() {
              final isSelected = _vm.selectedComponent.value == component;
              final color = componentColor(component);

              return _FilterChip(
                label: component.toUpperCase(),
                color: color,
                isSelected: isSelected,
                onTap: () => _vm.setComponentFilter(component),
              );
            });
          }),

          const SizedBox(width: FiftySpacing.sm),

          // Search field
          SizedBox(
            width: 180,
            height: 28,
            child: TextField(
              controller: _searchController,
              style: ArenaTextStyles.mono(
                context,
                fontSize: FiftyTypography.labelSmall,
                fontWeight: FiftyTypography.medium,
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Search events...',
                hintStyle: ArenaTextStyles.mono(
                  context,
                  fontSize: FiftyTypography.labelSmall,
                  fontWeight: FiftyTypography.medium,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: FiftySpacing.sm,
                  vertical: FiftySpacing.xs,
                ),
                filled: true,
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: FiftyRadii.smRadius,
                  borderSide: BorderSide(
                    color: colorScheme.outline,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: FiftyRadii.smRadius,
                  borderSide: BorderSide(
                    color: colorScheme.outline,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: FiftyRadii.smRadius,
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 1,
                  ),
                ),
              ),
            ),
          ),

          // Instance chip (when instance filter is active)
          Obx(() {
            if (_vm.selectedInstanceId.value == null) {
              return const SizedBox.shrink();
            }
            return _FilterChip(
              label:
                  'INSTANCE: ${_vm.instanceHostname.value ?? _vm.selectedInstanceId.value!.substring(0, _vm.selectedInstanceId.value!.length.clamp(0, 8))}',
              color: colorScheme.tertiary,
              isSelected: true,
              onTap: () => _vm.setInstanceFilter(null),
            );
          }),

          // Clear all button
          Obx(() {
            final hasFilter = _vm.selectedComponent.value != null ||
                _vm.searchQuery.value.isNotEmpty ||
                _vm.selectedInstanceId.value != null;

            if (!hasFilter) return const SizedBox.shrink();

            return _FilterChip(
              label: 'CLEAR',
              color: colorScheme.error,
              isSelected: false,
              onTap: () {
                _searchController.clear();
                _vm.clearFilters();
              },
            );
          }),
        ],
      ),
    );
  }
}

/// A single toggleable filter chip with color-coded styling.
class _FilterChip extends StatefulWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: FiftySpacing.sm,
            vertical: FiftySpacing.xs / 2,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.color.withValues(alpha: 0.2)
                : _hovered
                    ? widget.color.withValues(alpha: 0.1)
                    : Colors.transparent,
            borderRadius: FiftyRadii.fullRadius,
            border: Border.all(
              color: widget.isSelected
                  ? widget.color
                  : _hovered
                      ? widget.color.withValues(alpha: 0.5)
                      : colorScheme.outline,
              width: 1,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: FiftyTypography.fontFamily,
              fontSize: FiftyTypography.labelSmall,
              fontWeight:
                  widget.isSelected ? FiftyTypography.bold : FiftyTypography.medium,
              color: widget.isSelected
                  ? widget.color
                  : colorScheme.onSurfaceVariant,
              letterSpacing: FiftyTypography.letterSpacingLabel,
            ),
          ),
        ),
      ),
    );
  }
}
