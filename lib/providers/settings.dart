import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/system_orientation.dart';
import '../widgets/solitaire_theme.dart';

part 'settings.g.dart';

@riverpod
class AppThemeMode extends _$AppThemeMode with SharedPreferencesProviderMixin {
  @override
  final String key = "app_theme_mode";

  @override
  final ThemeMode defaultValue = ThemeMode.system;

  @override
  List<ThemeMode> get options => ThemeMode.values;

  @override
  ThemeMode build() => _get();
}

@riverpod
class AppThemeColor extends _$AppThemeColor
    with SharedPreferencesProviderMixin {
  @override
  final String key = "app_theme_color";

  @override
  final Color defaultValue = themeColorPalette.first;

  @override
  List<Color> get options => themeColorPalette;

  @override
  SettingsSerializer get serializer => SettingsSerializer(
        from: (raw) => Color(int.parse(raw, radix: 16)),
        to: (color) => color.value.toRadixString(16),
      );

  @override
  Color build() => _get();
}

@riverpod
class ColoredBackground extends _$ColoredBackground
    with SharedPreferencesProviderMixin {
  @override
  final String key = "colored_background";

  @override
  final bool defaultValue = false;

  @override
  bool build() => _get();
}

@riverpod
class AmoledBackground extends _$AmoledBackground
    with SharedPreferencesProviderMixin {
  @override
  final String key = "amoled_background";

  @override
  final bool defaultValue = false;

  @override
  bool build() => _get();
}

@riverpod
class StandardCardColor extends _$StandardCardColor
    with SharedPreferencesProviderMixin {
  @override
  final String key = "standard_card_color";

  @override
  final bool defaultValue = false;

  @override
  bool build() => _get();
}

@riverpod
class RandomizeThemeColor extends _$RandomizeThemeColor
    with SharedPreferencesProviderMixin {
  @override
  final String key = "randomize_theme_color";

  @override
  final bool defaultValue = false;

  @override
  bool build() => _get();
}

@riverpod
class AppScreenOrientation extends _$AppScreenOrientation
    with SharedPreferencesProviderMixin {
  @override
  final String key = "app_screen_orientation";

  @override
  final ScreenOrientation defaultValue = ScreenOrientation.auto;

  @override
  List<ScreenOrientation>? get options => ScreenOrientation.values;

  @override
  ScreenOrientation build() => _get();
}

@riverpod
class ShowLastMoves extends _$ShowLastMoves
    with SharedPreferencesProviderMixin {
  @override
  final String key = "show_last_moves";

  @override
  final bool defaultValue = true;

  @override
  bool build() => _get();
}

@riverpod
class ShowScore extends _$ShowScore with SharedPreferencesProviderMixin {
  @override
  final String key = "show_score";

  @override
  final bool defaultValue = true;

  @override
  bool build() => _get();
}

@riverpod
class ShowMoves extends _$ShowScore with SharedPreferencesProviderMixin {
  @override
  final String key = "show_moves";

  @override
  final bool defaultValue = true;

  @override
  bool build() => _get();
}

@riverpod
class ShowTime extends _$ShowTime with SharedPreferencesProviderMixin {
  @override
  final String key = "show_time";

  @override
  final bool defaultValue = true;

  @override
  bool build() => _get();
}

@riverpod
class OneTapMove extends _$OneTapMove with SharedPreferencesProviderMixin {
  @override
  final String key = "one_tap_move";

  @override
  final bool defaultValue = true;

  @override
  bool build() => _get();
}

@riverpod
class AutoPremove extends _$AutoPremove with SharedPreferencesProviderMixin {
  @override
  final String key = "auto_premove";

  @override
  final bool defaultValue = true;

  @override
  bool build() => _get();
}

@riverpod
class ShowAutoSolveButton extends _$ShowAutoSolveButton
    with SharedPreferencesProviderMixin {
  @override
  final String key = "show_auto_solve_button";

  @override
  final bool defaultValue = true;

  @override
  bool build() => _get();
}

// -----------------------------------------------------------------------------

@Riverpod(keepAlive: true)
Future<SharedPreferences> sharedPreference(SharedPreferenceRef ref) async {
  return await SharedPreferences.getInstance();
}

@riverpod
SharedPreferences? sharedPreferencesInstance(SharedPreferencesInstanceRef ref) {
  return ref.watch(sharedPreferenceProvider).value;
}

mixin SharedPreferencesProviderMixin<T> on AutoDisposeNotifier<T> {
  abstract final String key;

  abstract final T defaultValue;

  List<T>? get options => null;

  SettingsSerializer? get serializer => null;

  T _get() {
    final prefs = ref.watch(sharedPreferencesInstanceProvider);
    if (prefs == null) {
      return defaultValue;
    }
    final storedValue = _readFromPrefs(prefs, key);
    if (storedValue == null) {
      return defaultValue;
    }
    return storedValue as T;
  }

  void set(T value) {
    final prefs = ref.watch(sharedPreferencesInstanceProvider);
    if (prefs == null) {
      return;
    }
    _saveToPrefs(prefs, key, value);
    state = value;
  }

  void toggle() {
    final prefs = ref.watch(sharedPreferencesInstanceProvider);
    if (prefs == null) {
      return;
    }
    if (T == bool) {
      state = _saveToPrefs(prefs, key, !(state as bool) as T);
    } else if (options != null) {
      final opts = options!;
      final currentIndex = opts.indexOf(state);
      if (currentIndex >= 0) {
        // Roll over to next available options
        state =
            _saveToPrefs(prefs, key, opts[(currentIndex + 1) % opts.length]);
      } else {
        // If invalid option is provided, the default value is used
        state = _saveToPrefs(prefs, key, defaultValue);
      }
    } else {
      throw ArgumentError("toggling is not supported for type $T");
    }
  }

  // We couldn't check inheritance on T so we check on their instance instead, which is non-nullable defaultValue
  bool get _isEnum => defaultValue is Enum;

  T? _readFromPrefs(SharedPreferences prefs, String key) {
    switch (T) {
      case const (bool):
        return prefs.getBool(key) as T?;
      case const (int):
        return prefs.getInt(key) as T?;
      case const (double):
        return prefs.getDouble(key) as T?;
      case const (String):
        return prefs.getString(key) as T?;
      default:
        final storedValue = prefs.getString(key);
        if (storedValue == null) {
          return null;
        }
        if (_isEnum) {
          final opts = options;
          if (opts == null) {
            throw ArgumentError(
                "Please provide options list for enum settings");
          }
          final storedEnum = (opts as List<Enum>)
              .firstWhereOrNull((e) => e.name == storedValue);
          return storedEnum as T?;
        } else if (serializer != null) {
          return serializer!.from(storedValue);
        } else {
          throw ArgumentError(
              "Type $T is not supported. Please provide a serializer");
        }
    }
  }

  T _saveToPrefs(SharedPreferences prefs, String key, T value) {
    switch (T) {
      case const (bool):
        prefs.setBool(key, (value ?? defaultValue) as bool);
      case const (int):
        prefs.setInt(key, (value ?? defaultValue) as int);
      case const (double):
        prefs.setDouble(key, (value ?? defaultValue) as double);
      case const (String):
        prefs.setString(key, (value ?? defaultValue) as String);
      default:
        if (_isEnum) {
          final opts = options;
          if (opts == null) {
            throw ArgumentError(
                "Please provide options list for enum settings");
          }
          final valueEnum = (opts as List<Enum>).firstWhere((e) => e == value);
          prefs.setString(key, valueEnum.name);
        } else if (serializer != null) {
          prefs.setString(key, serializer!.to(value));
        } else {
          throw ArgumentError(
              "Type $T is not supported. Please provide a serializer");
        }
    }
    return value;
  }
}

class SettingsSerializer<T> {
  final T Function(String raw) from;

  final String Function(T value) to;

  SettingsSerializer({required this.from, required this.to});
}
