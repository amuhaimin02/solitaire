import 'package:flutter/material.dart';

import '../animations.dart';
import '../utils/math.dart';

class SimpleBackground extends StatelessWidget {
  const SimpleBackground({super.key, required this.color, required this.child});

  final Color color;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: themeChangeAnimation.duration,
      curve: themeChangeAnimation.curve,
      color: color,
      child: child,
    );
  }
}

class RippleBackground extends StatefulWidget {
  const RippleBackground({
    super.key,
    required this.child,
    required this.color,
  });

  final Color color;

  final Widget child;

  @override
  State<RippleBackground> createState() => _RippleBackgroundState();
}

class _RippleBackgroundState extends State<RippleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _animation;

  late Color _color;

  late Offset _rippleOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: themeChangeAnimation.duration);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _color = widget.color;
        });
      }
    });
    _animation =
        CurveTween(curve: themeChangeAnimation.curve).animate(_controller);

    _color = widget.color;
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  void didUpdateWidget(covariant RippleBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.color != oldWidget.color) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerUp: (event) {
        _rippleOffset = event.localPosition;
      },
      child: _buildChild(context),
    );
  }

  Widget _buildChild(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final parentSize = constraints.biggest;
        final rippleCenter = _rippleOffset;

        final circleRadius = findDistanceToFarthestRectCorner(
          Offset.zero & parentSize,
          rippleCenter,
        );

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final oldColor = _color;
            final newColor = widget.color;

            return Stack(
              children: [
                Positioned.fill(
                  child: Material(color: oldColor),
                ),
                OverflowBox(
                  maxWidth: double.infinity,
                  maxHeight: double.infinity,
                  child: Transform.translate(
                    offset: _rippleOffset - parentSize.center(Offset.zero),
                    child: SizedBox(
                      width: _animation.value * circleRadius * 2,
                      height: _animation.value * circleRadius * 2,
                      child: Material(
                        color: newColor,
                        shape: const CircleBorder(),
                      ),
                    ),
                  ),
                ),
                widget.child,
              ],
            );
          },
        );
      },
    );
  }
}
