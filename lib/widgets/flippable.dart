import 'package:flutter/material.dart';

class Flippable extends StatefulWidget {
  const Flippable({
    super.key,
    required this.flipped,
    required this.front,
    required this.back,
    required this.duration,
    this.curve = standardEasing,
  });

  final bool flipped;
  final Widget front;
  final Widget back;

  final Duration duration;

  final Curve curve;

  @override
  State<Flippable> createState() => _FlippableState();
}

class _FlippableState extends State<Flippable>
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
    _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(Flippable oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.flipped != oldWidget.flipped) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _controller.forward(from: 0.0);
  }

  final _scaleTween = TweenSequence(
    [
      TweenSequenceItem(
        tween:
            Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.linear)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween:
            Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.linear)),
        weight: 1,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final child = switch (widget.flipped) {
          true => _animation.value < 0.5 ? widget.front : widget.back,
          false => _animation.value < 0.5 ? widget.back : widget.front,
        };

        return MatrixTransition(
          animation: _scaleTween.animate(_animation),
          onTransform: (value) {
            return Matrix4.identity()..scale(value, 1, 1);
          },
          child: child,
        );
      },
    );
  }
}
