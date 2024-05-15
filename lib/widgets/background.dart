import 'dart:math';

import 'package:flutter/material.dart';

import '../animations.dart';
import '../utils/math.dart';

class Background extends StatefulWidget {
  const Background({
    super.key,
    required this.child,
    required this.color,
  });

  final Color color;

  final Widget child;

  static BackgroundState? maybeOf(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_BackgroundScope>();
    return scope?.state;
  }

  static BackgroundState of(BuildContext context) {
    final result = maybeOf(context);
    assert(result != null, 'No Background widget found in context');
    return result!;
  }

  @override
  State<Background> createState() => BackgroundState();
}

class _BackgroundScope extends InheritedWidget {
  const _BackgroundScope({
    required super.child,
    required this.state,
  });

  final BackgroundState state;

  @override
  bool updateShouldNotify(_BackgroundScope old) => false;
}

class BackgroundState extends State<Background>
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
  void didUpdateWidget(covariant Background oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.color != oldWidget.color) {
      _controller.forward(from: 0.0);
    }
  }

  void setRippleCenter(Offset offset) {
    _rippleOffset = offset;
  }

  @override
  Widget build(BuildContext context) {
    return _BackgroundScope(
      state: this,
      child: _buildChild(context),
    );
  }

  Widget _buildChild(BuildContext context) {
    if (_controller.status == AnimationStatus.forward) {
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
                  Positioned.fill(child: Container(color: oldColor)),
                  OverflowBox(
                    maxWidth: double.infinity,
                    maxHeight: double.infinity,
                    child: Transform.translate(
                      offset: _rippleOffset - parentSize.center(Offset.zero),
                      child: Container(
                        width: _animation.value * circleRadius * 2,
                        height: _animation.value * circleRadius * 2,
                        decoration: BoxDecoration(
                          color: newColor,
                          shape: BoxShape.circle,
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
    } else {
      return Container(
        color: _color,
        child: widget.child,
      );
    }
  }
}
