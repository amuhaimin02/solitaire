import 'dart:ui';

void drawShape(Canvas canvas, List<Offset> points, Paint paint) {
  final path = Path();

  if (points.length <= 2) {
    throw ArgumentError('Must have at least 3 points to draw a shape');
  }

  path.moveTo(points.first.dx, points.first.dy);

  for (final point in points.skip(1)) {
    path.lineTo(point.dx, point.dy);
  }

  path.close();

  canvas.drawPath(path, paint);
}
