import 'package:flutter/material.dart';

class DurationCurve {
  final Duration duration;
  final Curve curve;

  const DurationCurve(this.duration, this.curve);

  static const zero = DurationCurve(Duration.zero, Curves.linear);

  DurationCurve delayed(Duration delay) {
    final totalDuration = duration + delay;
    return DurationCurve(
      totalDuration,
      Interval(delay.inMicroseconds / totalDuration.inMicroseconds, 1.0,
          curve: curve),
    );
  }

  DurationCurve timeScaled(double slowFactor) {
    return DurationCurve(duration * slowFactor, curve);
  }

  @override
  String toString() {
    return 'DurationCurve($duration, $curve)';
  }
}

const cardMoveAnimation =
    DurationCurve(Duration(milliseconds: 300), Easing.standard);

const cardDragAnimation =
    DurationCurve(Duration(milliseconds: 200), Curves.easeOutCirc);

const standardAnimation =
    DurationCurve(Duration(milliseconds: 250), Curves.fastOutSlowIn);

const themeChangeAnimation =
    DurationCurve(Duration(milliseconds: 700), Easing.standard);

const numberTickAnimation =
    DurationCurve(Duration(milliseconds: 250), Curves.fastOutSlowIn);

final autoMoveDelay = cardMoveAnimation.duration * 0.7;
