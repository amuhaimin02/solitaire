import 'package:flutter/widgets.dart';

class DurationCurve {
  final Duration duration;
  final Curve curve;

  const DurationCurve(this.duration, this.curve);
}

const cardMoveAnimation =
    DurationCurve(Duration(milliseconds: 300), Curves.fastOutSlowIn);

const themeChangeAnimation =
    DurationCurve(Duration(milliseconds: 500), Curves.fastOutSlowIn);
