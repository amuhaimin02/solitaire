import 'dart:math';

import 'package:flutter/material.dart';

class LeveledProgressRing extends StatelessWidget {
  const LeveledProgressRing({
    super.key,
    required this.value,
  });

  final double value;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LeveledProgressRingPainter(
        value: value,
        colorScheme: Theme.of(context).colorScheme,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _LeveledProgressRingPainter extends CustomPainter {
  final double value;
  final ColorScheme colorScheme;

  static const trackWidth = 4.0;
  static const ringWidth = 8.0;

  _LeveledProgressRingPainter(
      {super.repaint, required this.value, required this.colorScheme});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2;
    final center = size.center(Offset.zero);

    final Paint trackPaint = Paint()
      ..color = colorScheme.onSurface.withOpacity(0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackWidth;

    canvas.drawCircle(center, radius - ringWidth / 2, trackPaint);

    final Paint ringPaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = ringWidth;

    canvas.drawArc(
      Rect.fromCenter(
        center: center,
        width: radius * 2 - ringWidth,
        height: radius * 2 - ringWidth,
      ),
      -pi / 2, // Start from top (-90 degrees)
      value * 2 * pi, // value = 1 equates to full rotation (2 * pi)
      false,
      ringPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LeveledProgressRingPainter oldDelegate) {
    return value != oldDelegate.value || colorScheme != oldDelegate.colorScheme;
  }
}
