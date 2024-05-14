import 'package:flutter/widgets.dart';

class DurationCurve {
  final Duration duration;
  final Curve curve;

  const DurationCurve(this.duration, this.curve);

  DurationCurve delayed(Duration delay) {
    final totalDuration = duration + delay;
    return DurationCurve(
      totalDuration,
      Interval(delay.inMilliseconds / totalDuration.inMilliseconds, 1.0,
          curve: curve),
    );
  }
}

const cardMoveAnimation =
    DurationCurve(Duration(milliseconds: 250), Curves.fastOutSlowIn);

const standardAnimation =
    DurationCurve(Duration(milliseconds: 250), Curves.fastOutSlowIn);

const themeChangeAnimation =
    DurationCurve(Duration(milliseconds: 400), Curves.fastOutSlowIn);

const numberTickAnimation =
    DurationCurve(Duration(milliseconds: 250), Curves.fastOutSlowIn);