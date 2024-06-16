import 'package:flutter/material.dart';
import 'package:material_color_utilities/hct/hct.dart';
import 'package:material_color_utilities/palettes/tonal_palette.dart';

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

extension MaterialColorExtension on Color {
  TonalPalette get tonalPalette {
    final hctColor = Hct.fromInt(value);
    return TonalPalette.of(hctColor.hue, hctColor.chroma);
  }
}
