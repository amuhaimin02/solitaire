import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/game_theme.dart';
import '../models/serializer.dart';
import 'shared_preferences.dart';

part 'themes.g.dart';

@riverpod
class ThemeBaseMode extends _$ThemeBaseMode
    with SharedPreferencesProviderMixin {
  @override
  final String key = 'theme_base_mode';

  @override
  final ThemeMode defaultValue = ThemeMode.system;

  @override
  List<ThemeMode> get options => ThemeMode.values;

  @override
  ThemeMode build() => get();
}

@riverpod
class ThemeBaseColor extends _$ThemeBaseColor
    with SharedPreferencesProviderMixin {
  @override
  final String key = 'theme_base_color';

  @override
  final Color defaultValue = themeColorPalette.first;

  @override
  List<Color> get options => themeColorPalette;

  @override
  Serializer get serializer => const ColorSerializer();

  @override
  Color build() => get();
}

@riverpod
class ThemeTableBackgroundStyle extends _$ThemeTableBackgroundStyle
    with SharedPreferencesProviderMixin {
  @override
  final String key = 'theme_table_background_style';

  @override
  List<TableBackgroundStyle>? get options => TableBackgroundStyle.values;

  @override
  TableBackgroundStyle defaultValue = TableBackgroundStyle.simple;

  @override
  TableBackgroundStyle build() => get();
}

@riverpod
class ThemeBackgroundAmoled extends _$ThemeBackgroundAmoled
    with SharedPreferencesProviderMixin {
  @override
  final String key = 'theme_background_amoled';

  @override
  final bool defaultValue = false;

  @override
  bool build() => get();
}

@riverpod
class ThemeBaseRandomizeColor extends _$ThemeBaseRandomizeColor
    with SharedPreferencesProviderMixin {
  @override
  final String key = 'theme_base_randomize_color';

  @override
  final bool defaultValue = false;

  @override
  bool build() => get();

  void tryShuffleColor() {
    // If enabled, try change the base color
    if (state) {
      final currentColor = ref.read(themeBaseColorProvider);
      Color newColor;
      do {
        newColor = themeColorPalette.sample(1).single;
      } while (newColor == currentColor);
      ref.read(themeBaseColorProvider.notifier).set(newColor);
    }
  }
}

@riverpod
class ThemeCompressCardStack extends _$ThemeCompressCardStack
    with SharedPreferencesProviderMixin {
  @override
  final String key = 'theme_compress_card_stack';

  @override
  final bool defaultValue = false;

  @override
  bool build() => get();
}

@riverpod
class ThemeCardFaceStyle extends _$ThemeCardFaceStyle
    with SharedPreferencesProviderMixin {
  @override
  final String key = 'theme_card_face_style';

  @override
  CardFaceStyle defaultValue = CardFaceStyle.accent;

  @override
  List<CardFaceStyle>? get options => CardFaceStyle.values;

  @override
  CardFaceStyle build() => get();
}

@riverpod
class ThemeCardBackStyle extends _$ThemeCardBackStyle
    with SharedPreferencesProviderMixin {
  @override
  final String key = 'theme_card_back_style';

  @override
  final CardBackStyle defaultValue = CardBackStyle.solid;

  @override
  List<CardBackStyle>? get options => CardBackStyle.values;

  @override
  CardBackStyle build() => get();
}
