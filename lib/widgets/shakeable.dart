import 'dart:math';

import 'package:flutter/material.dart';

class Shakeable extends StatefulWidget {
  const Shakeable({
    super.key,
    required this.child,
    this.shake = false,
    required this.duration,
    this.curve = Easing.standard,
    this.intensity = 0.2,
  });

  final bool shake;

  final Widget child;

  final Duration duration;

  final Curve curve;

  final double intensity;

  @override
  State<Shakeable> createState() => _ShakeableState();
}

class _ShakeableState extends State<Shakeable>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurveTween(curve: widget.curve).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant Shakeable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.shake && widget.shake) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.shake) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform(
          transform: Matrix4.identity()
            ..rotateX(sin(_animation.value * 2 * pi) * widget.intensity * 2)
            ..rotateZ(sin(_animation.value * 2 * pi) * widget.intensity),
          alignment: Alignment.center,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
