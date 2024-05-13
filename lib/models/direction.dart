class Direction {
  static const none = Direction(0, 0);
  static const up = Direction(0, -1);
  static const down = Direction(0, 1);
  static const left = Direction(-1, 0);
  static const right = Direction(1, 0);

  const Direction(this.dx, this.dy);
  final int dx, dy;
  Direction get opposite => Direction(-dx, -dy);
}
