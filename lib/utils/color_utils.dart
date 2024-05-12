import 'package:flutter/material.dart';

extension ColorExtension on Color {
  Color lighten(double strength) {
    assert(strength >= 0 && strength <= 1);

    final hsl = HSLColor.fromColor(this);

    final newLightness = hsl.lightness + strength * (1 - hsl.lightness);

    return hsl.withLightness(newLightness).toColor();
  }

  Color darken(double strength) {
    assert(strength >= 0 && strength <= 1);

    final hsl = HSLColor.fromColor(this);

    final newLightness = hsl.lightness - strength * hsl.lightness;

    return hsl.withLightness(newLightness).toColor();
  }
}
