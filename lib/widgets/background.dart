import 'dart:math';

import 'package:flutter/material.dart';

import '../animations.dart';

class Background extends StatefulWidget {
  const Background({
    super.key,
    required this.child,
    required this.color,
  });

  final Color color;

  final Widget child;

  @override
  State<Background> createState() => _BackgroundState();
}

class _BackgroundState extends State<Background>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _animation;

  late Color _color;

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
  void didUpdateWidget(covariant Background oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.color != oldWidget.color) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.status == AnimationStatus.forward) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final parentSize = constraints.biggest;

          final circleDiameter = sqrt(parentSize.width * parentSize.width +
              parentSize.height * parentSize.height);

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final oldColor = _color;
              final newColor = widget.color;

              return Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(child: Container(color: oldColor)),
                  OverflowBox(
                    maxWidth: double.infinity,
                    maxHeight: double.infinity,
                    child: Container(
                      width: _animation.value * circleDiameter,
                      height: _animation.value * circleDiameter,
                      decoration: BoxDecoration(
                          color: newColor, shape: BoxShape.circle),
                    ),
                  ),
                  widget.child,
                ],
              );
            },
          );
        },
      );
    } else {
      return Container(
        color: _color,
        child: widget.child,
      );
    }
  }
}
