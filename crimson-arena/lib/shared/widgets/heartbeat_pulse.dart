import 'package:crimson_arena/core/constants/arena_sizes.dart';
import 'package:flutter/material.dart';

/// An animated pulsing dot indicating live status.
///
/// Renders two concentric circles: a solid inner circle and an outer
/// ring that pulses with an opacity animation. When [isAnimated] is
/// false, the dot renders as a static solid circle with no animation.
///
/// The [AnimationController] is properly disposed when the widget is
/// removed from the tree.
class HeartbeatPulse extends StatefulWidget {
  /// The color of the pulse dot.
  final Color color;

  /// Whether the pulse animation should be active.
  /// When false, a static dot is rendered.
  final bool isAnimated;

  /// Diameter of the inner dot in logical pixels.
  final double size;

  const HeartbeatPulse({
    super.key,
    required this.color,
    this.isAnimated = true,
    this.size = 8,
  });

  @override
  State<HeartbeatPulse> createState() => _HeartbeatPulseState();
}

class _HeartbeatPulseState extends State<HeartbeatPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: ArenaSizes.heartbeatDuration,
    );

    _opacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      // Organic heartbeat -- intentionally not FiftyMotion (UI curves)
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.isAnimated) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(HeartbeatPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimated != oldWidget.isAnimated) {
      if (widget.isAnimated) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotSize = widget.size;
    // Reserve space for the pulse ring at max scale (2.2x).
    // The outermost ring fades to zero opacity at max scale,
    // so slight clipping at the edge is imperceptible.
    final containerSize = widget.isAnimated ? dotSize * 2.2 : dotSize;

    return SizedBox(
      width: containerSize,
      height: containerSize,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulsing ring (only when animated)
            if (widget.isAnimated)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color
                            .withValues(alpha: _opacityAnimation.value),
                      ),
                    ),
                  );
                },
              ),

            // Inner solid dot (always visible)
            Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: widget.isAnimated
                    ? [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.5),
                          blurRadius: ArenaSizes.heartbeatBlurRadius,
                          spreadRadius: ArenaSizes.heartbeatSpreadRadius,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
