import 'package:flutter/material.dart';

import '../animations.dart';
import '../utils/math.dart';

class RippleBackground extends StatefulWidget {
  const RippleBackground({
    super.key,
    required this.child,
    required this.decoration,
  });

  final BoxDecoration decoration;

  final Widget child;

  @override
  State<RippleBackground> createState() => _RippleBackgroundState();
}

class _RippleBackgroundState extends State<RippleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _animation;

  late BoxDecoration _lastDecoration;

  Offset? _rippleOffset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: themeChangeAnimation.duration);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _lastDecoration = widget.decoration;
        });
      }
    });
    _animation =
        CurveTween(curve: themeChangeAnimation.curve).animate(_controller);

    _lastDecoration = widget.decoration;
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  void didUpdateWidget(covariant RippleBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.decoration != oldWidget.decoration) {
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
        final rippleCenter =
            _rippleOffset ?? constraints.biggest.center(Offset.zero);

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final oldDecoration = _lastDecoration;
            final newDecoration = widget.decoration;

            return Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(decoration: oldDecoration),
                ),
                Positioned.fill(
                  child: ClipOval(
                    clipper:
                        _AnimatedCircleClipper(_animation.value, rippleCenter),
                    child: DecoratedBox(decoration: newDecoration),
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

class _AnimatedCircleClipper extends CustomClipper<Rect> {
  const _AnimatedCircleClipper(this.animationValue, this.center);

  final double animationValue;
  final Offset center;

  @override
  Rect getClip(Size size) {
    final circleRadius =
        findDistanceToFarthestRectCorner(Offset.zero & size, center) *
            animationValue;

    return Rect.fromLTWH(
      center.dx - circleRadius,
      center.dy - circleRadius,
      circleRadius * 2,
      circleRadius * 2,
    );
  }

  @override
  bool shouldReclip(covariant _AnimatedCircleClipper oldClipper) {
    return animationValue != oldClipper.animationValue ||
        center != oldClipper.center;
  }
}
