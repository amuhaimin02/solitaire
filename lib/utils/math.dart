import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';

double findDistanceToFarthestRectCorner(Rect rect, Offset point) {
  final rectPoints = [
    rect.topLeft,
    rect.topRight,
    rect.bottomRight,
    rect.bottomLeft
  ];

  final distances =
      rectPoints.map((corner) => (corner - point).distanceSquared);

  return sqrt(distances.max);
}
