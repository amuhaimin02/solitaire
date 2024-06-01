import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/serializer.dart';
import '../services/shared_preferences.dart';
import '../widgets/solitaire_theme.dart';

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
class ThemeBackgroundColored extends _$ThemeBackgroundColored
    with SharedPreferencesProviderMixin {
  @override
  final String key = 'theme_background_colored';

  @override
  final bool defaultValue = false;

  @override
  bool build() => get();
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
class ThemeUseClassicCardColors extends _$ThemeUseClassicCardColors
    with SharedPreferencesProviderMixin {
  @override
  final String key = 'theme_use_classic_card_colors';

  @override
  final bool defaultValue = false;

  @override
  bool build() => get();
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
