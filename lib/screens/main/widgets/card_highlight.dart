import 'dart:math';

import 'package:flutter/material.dart';

import '../../../animations.dart';
import '../../../models/game_theme.dart';

class ColorSpectrumCardHighlight extends StatefulWidget {
  const ColorSpectrumCardHighlight({
    super.key,
    required this.highlight,
    required this.size,
    required this.child,
  });

  final bool highlight;

  final Size size;

  final Widget child;

  @override
  State<ColorSpectrumCardHighlight> createState() =>
      _ColorSpectrumCardHighlightState();
}

class _ColorSpectrumCardHighlightState extends State<ColorSpectrumCardHighlight>
    with SingleTickerProviderStateMixin {
  // Number of points for filling up SweepGradient. The more the finer. Must be greater than 2
  static const gradientStops = 8;

  late AnimationController _controller;

  bool _gradientAnimationActive = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ColorSpectrumCardHighlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlight != oldWidget.highlight) {
      if (widget.highlight) {
        _startGradientAnimation();
      }
    }
  }

  void _startGradientAnimation() {
    print("start gradient");
    setState(() {
      _gradientAnimationActive = true;
    });
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
    const baseColorHSV = HSVColor.fromAHSV(1, 0, 0.7, 1);

    final gradientColorPoints = [
      for (int i = 0; i < gradientStops; i++)
        baseColorHSV.withHue(i / gradientStops * 360),
      baseColorHSV.withHue(360)
    ].map((hsv) => hsv.toColor()).toList();

    final gradientStopPoints = [
      for (int i = 0; i < gradientStops; i++) i / gradientStops,
      1.0,
    ].toList();

    return Stack(
      children: [
        AnimatedScale(
          duration: cardMoveAnimation.duration,
          curve: widget.highlight ? Curves.easeOutCirc : Curves.easeInCirc,
          scale: widget.highlight ? 1 : 0.5,
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
                                (cardTheme.cornerRadius + cardTheme.margin)),
                      )
                    : null,
              );
            },
          ),
          onEnd: () {
            if (!widget.highlight) {
              _stopGradientAnimation();
            }
          },
        ),
        Positioned.fill(child: widget.child),
      ],
    );
  }
}
