import 'package:fifty_tokens/fifty_tokens.dart';
import 'package:flutter/material.dart';

/// A button with hover feedback: background tint appears on mouse hover.
///
/// Supports an optional [disabled] state that dims the child and
/// prevents interaction. Used throughout the dashboard for small
/// text-based action buttons (REFRESH, PREV, NEXT, CLEAR, etc.).
class ArenaHoverButton extends StatefulWidget {
  /// Tap callback. When `null` or when [disabled] is true, the button
  /// renders as non-interactive.
  final VoidCallback? onTap;

  /// Content displayed inside the button.
  final Widget child;

  /// When true the button is visually dimmed and ignores taps.
  final bool disabled;

  const ArenaHoverButton({
    super.key,
    this.onTap,
    required this.child,
    this.disabled = false,
  });

  @override
  State<ArenaHoverButton> createState() => _ArenaHoverButtonState();
}

class _ArenaHoverButtonState extends State<ArenaHoverButton> {
  bool _hovered = false;

  bool get _isActive => !widget.disabled && widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      cursor: _isActive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: _isActive ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: FiftySpacing.sm,
            vertical: FiftySpacing.xs,
          ),
          decoration: BoxDecoration(
            color: _hovered && _isActive
                ? colorScheme.onSurface.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: FiftyRadii.smRadius,
            border: Border.all(
              color: _hovered && _isActive
                  ? colorScheme.outline
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Opacity(
            opacity: _isActive ? 1.0 : 0.5,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
