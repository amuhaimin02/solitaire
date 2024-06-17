import 'dart:math';

import 'package:flutter/material.dart';

import '../../../animations.dart';
import '../../../models/game_theme.dart';
import '../../../widgets/pulsating.dart';

class BlinkingCardHighlight extends StatefulWidget {
  const BlinkingCardHighlight({
    super.key,
    this.active = false,
    required this.size,
    required this.color,
    required this.child,
  });

  final bool active;

  final Size size;

  final Color color;

  final Widget child;

  @override
  State<BlinkingCardHighlight> createState() => _BlinkingCardHighlightState();
}

class _BlinkingCardHighlightState extends State<BlinkingCardHighlight> {
  @override
  Widget build(BuildContext context) {
    final cardTheme = Theme.of(context).gameCardTheme;

    return Stack(
      children: [
        if (widget.active)
          Pulsating(
            child: Container(
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(
                  widget.size.shortestSide *
                      (cardTheme.cornerRadius + cardTheme.margin),
                ),
              ),
            ),
          ),
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

class ColorWheelCardHighlight extends StatefulWidget {
  const ColorWheelCardHighlight({
    super.key,
    required this.active,
    required this.size,
    required this.child,
  });

  final bool active;

  final Size size;

  final Widget child;

  @override
  State<ColorWheelCardHighlight> createState() =>
      _ColorWheelCardHighlightState();
}

class _ColorWheelCardHighlightState extends State<ColorWheelCardHighlight>
    with SingleTickerProviderStateMixin {
  // Number of points for filling up SweepGradient. The more the finer. Must be greater than 2
  static const _gradientStops = 8;

  // Duration on how fast color rotates
  static const _animationDuration = Duration(seconds: 1);

  late AnimationController _controller;

  bool _gradientAnimationActive = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ColorWheelCardHighlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      if (widget.active) {
        _startGradientAnimation();
      }
    }
  }

  void _startGradientAnimation() {
    setState(() {
      _gradientAnimationActive = true;
    });
    _controller.reset();
    _controller.repeat();
  }

  void _stopGradientAnimation() {
    setState(() {
      _gradientAnimationActive = false;
    });
    _controller.stop();
  }

  @override
  Widget build(BuildContext context) {
    final cardTheme = Theme.of(context).gameCardTheme;
    const baseColorHSL = HSLColor.fromAHSL(1, 0, 0.7, 0.5);

    final gradientColorPoints = [
      for (int i = 0; i < _gradientStops; i++)
        baseColorHSL.withHue(i / _gradientStops * 360),
      baseColorHSL.withHue(360)
    ].map((hsl) => hsl.toColor()).toList();

    final gradientStopPoints = [
      for (int i = 0; i < _gradientStops; i++) i / _gradientStops,
      1.0,
    ].toList();

    return Stack(
      children: [
        AnimatedScale(
          duration: cardMoveAnimation.duration,
          curve: widget.active ? Curves.easeOutCirc : Curves.easeInCirc,
          scale: widget.active ? 1 : 0.5,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                decoration: _gradientAnimationActive
                    ? BoxDecoration(
                        gradient: SweepGradient(
                          colors: gradientColorPoints,
                          stops: gradientStopPoints,
                          transform:
                              GradientRotation(2 * pi * _controller.value),
                        ),
                        borderRadius: BorderRadius.circular(
                          widget.size.shortestSide *
                              (cardTheme.cornerRadius + cardTheme.margin),
                        ),
                      )
                    : null,
              );
            },
          ),
          onEnd: () {
            if (!widget.active) {
              _stopGradientAnimation();
            }
          },
        ),
        Positioned.fill(child: widget.child),
      ],
    );
  }
}
