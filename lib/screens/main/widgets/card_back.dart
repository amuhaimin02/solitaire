import 'package:flutter/material.dart';

import '../../../models/game_theme.dart';
import '../../../utils/canvas.dart';

class CardBack extends StatelessWidget {
  const CardBack({super.key, required this.size});

  final Size size;

  @override
  Widget build(BuildContext context) {
    final cardTheme = Theme.of(context).gameCardTheme;

    final painter = switch (cardTheme.backStyle) {
      CardBackStyle.solid => SolidCardCover(color: cardTheme.backColor),
      CardBackStyle.gradient => GradientCardCover(
          color: cardTheme.backColor,
          secondaryColor: cardTheme.backSecondaryColor),
    };
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(size.shortestSide * cardTheme.cornerRadius),
      child: CustomPaint(
        painter: painter,
      ),
    );
  }
}

class SolidCardCover extends CustomPainter {
  final Color color;

  SolidCardCover({
    super.repaint,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final drawArea = Offset.zero & size;
    final paint = Paint();

    paint.color = color;
    canvas.drawRect(drawArea, paint);
  }

  @override
  bool shouldRepaint(covariant SolidCardCover oldDelegate) {
    return color != oldDelegate.color;
  }
}

class GradientCardCover extends CustomPainter {
  final Color color;
  final Color? secondaryColor;

  GradientCardCover({
    super.repaint,
    required this.color,
    this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final drawArea = Offset.zero & size;
    final paint = Paint();

    if (secondaryColor != null) {
      paint.shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [color, secondaryColor!],
      ).createShader(drawArea);
    } else {
      paint.color = color;
    }
    canvas.drawRect(drawArea, paint);
  }

  @override
  bool shouldRepaint(covariant GradientCardCover oldDelegate) {
    return color != oldDelegate.color;
  }
}

class FourTrianglesCardCover extends CustomPainter {
  final Color color;
  final Color secondaryColor;

  FourTrianglesCardCover({
    super.repaint,
    required this.color,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final drawArea = Offset.zero & size;
    final paint = Paint();

    paint.color = color;
    canvas.drawRect(drawArea, paint);

    final center = drawArea.center;
    final topLeft = drawArea.topLeft;
    final bottomLeft = drawArea.bottomLeft;
    final topRight = drawArea.topRight;
    final bottomRight = drawArea.bottomRight;

    paint.color = Color.lerp(color, secondaryColor, 0.33)!;
    drawShape(canvas, [center, topRight, bottomRight], paint);

    paint.color = Color.lerp(color, secondaryColor, 0.66)!;
    drawShape(canvas, [center, topLeft, bottomLeft], paint);

    paint.color = Color.lerp(color, secondaryColor, 1)!;
    drawShape(canvas, [center, bottomLeft, bottomRight], paint);
  }

  @override
  bool shouldRepaint(covariant FourTrianglesCardCover oldDelegate) {
    return color != oldDelegate.color;
  }
}

class FourBordersCardCover extends CustomPainter {
  final Color color;
  final Color secondaryColor;

  final double borderSizeRatio;
  FourBordersCardCover({
    super.repaint,
    required this.color,
    required this.secondaryColor,
    required this.borderSizeRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final drawArea = Offset.zero & size;
    final paint = Paint();

    final center = drawArea.center;
    final topLeft = drawArea.topLeft;
    final bottomLeft = drawArea.bottomLeft;
    final topRight = drawArea.topRight;
    final bottomRight = drawArea.bottomRight;

    final topLeftInner = Offset.lerp(topLeft, center, borderSizeRatio)!;
    final bottomLeftInner = Offset.lerp(bottomLeft, center, borderSizeRatio)!;
    final topRightInner = Offset.lerp(topRight, center, borderSizeRatio)!;
    final bottomRightInner = Offset.lerp(bottomRight, center, borderSizeRatio)!;

    paint.color = Color.lerp(color, secondaryColor, 0.5)!;
    canvas.drawRect(drawArea, paint);

    paint.color = Color.lerp(color, secondaryColor, 0)!;
    drawShape(canvas, [topLeft, topLeftInner, topRightInner, topRight], paint);

    paint.color = Color.lerp(color, secondaryColor, 0.25)!;
    drawShape(canvas, [topRight, topRightInner, bottomRightInner, bottomRight],
        paint);

    paint.color = Color.lerp(color, secondaryColor, 0.75)!;
    drawShape(
        canvas, [topLeft, topLeftInner, bottomLeftInner, bottomLeft], paint);

    paint.color = Color.lerp(color, secondaryColor, 1)!;
    drawShape(canvas,
        [bottomLeft, bottomLeftInner, bottomRightInner, bottomRight], paint);
  }

  @override
  bool shouldRepaint(covariant FourBordersCardCover oldDelegate) {
    return color != oldDelegate.color;
  }
}

class LayeredBorderCardCover extends CustomPainter {
  final Color color;
  final Color secondaryColor;

  LayeredBorderCardCover({
    super.repaint,
    required this.color,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final drawArea = Offset.zero & size;
    final paint = Paint();

    final center = drawArea.center;
    final topLeft = drawArea.topLeft;
    final bottomLeft = drawArea.bottomLeft;
    final topRight = drawArea.topRight;
    final bottomRight = drawArea.bottomRight;

    paint.color = Color.lerp(color, secondaryColor, 0)!;
    canvas.drawRect(drawArea, paint);

    for (final ratio in [1 / 3]) {
      final topLeftInner = Offset.lerp(topLeft, center, ratio)!;
      final bottomLeftInner = Offset.lerp(bottomLeft, center, ratio)!;
      final topRightInner = Offset.lerp(topRight, center, ratio)!;
      final bottomRightInner = Offset.lerp(bottomRight, center, ratio)!;

      paint.color = Color.lerp(color, secondaryColor, ratio)!;
      drawShape(
          canvas,
          [topLeftInner, topRightInner, bottomRightInner, bottomLeftInner],
          paint);
    }
  }

  @override
  bool shouldRepaint(covariant LayeredBorderCardCover oldDelegate) {
    return color != oldDelegate.color;
  }
}
