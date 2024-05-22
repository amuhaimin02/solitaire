import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pile.dart';
import '../utils/lists.dart';
import '../utils/system_orientation.dart';

enum Settings<T> {
  autoMoveLevel(
    defaultValue: AutoMoveLevel.off,
    options: AutoMoveLevel.values,
  ),

  showDebugPanel(defaultValue: false),

  showMoveHighlight(defaultValue: false),

  showMovesDuringPlay(defaultValue: true),

  showTimeDuringPlay(defaultValue: true),

  showScoreDuringPlay(defaultValue: true),

  showAutoSolveButton(defaultValue: true),

  oneTapMove(defaultValue: true),

  randomizeThemeColor(defaultValue: true),

  screenOrientation(
    defaultValue: ScreenOrientation.auto,
    options: ScreenOrientation.values,
    preload: true,
    onChange: ScreenOrientationManager.change,
  ),

  themeMode(
    defaultValue: ThemeMode.system,
    options: ThemeMode.values,
  ),

  coloredBackground(defaultValue: false),

  useStandardCardColors(defaultValue: false),

  themeColor<Color>(
    defaultValue: Colors.transparent,
    convertFrom: ColorSerializer.from,
    convertTo: ColorSerializer.to,
  ),

  amoledDarkTheme(defaultValue: false);

  // ----------------------------------------

  final T defaultValue;

  final List<T>? options;

  final void Function(T)? onChange;

  final bool preload;

  final T Function(String raw)? convertFrom;
  final String Function(T value)? convertTo;

  Type get type => defaultValue.runtimeType;

  bool get isEnum => defaultValue is Enum;

  const Settings({
    required this.defaultValue,
    this.onChange,
    this.options,
    this.preload = false,
    this.convertFrom,
    this.convertTo,
  });

  void triggerOnChange(T newValue) {
    onChange?.call(newValue);
  }
}

class SettingsManager with ChangeNotifier {
  bool _isPreloaded = false;
  late SharedPreferences _prefs;

  Map<Settings, dynamic>? _cache;

  SettingsManager() {
    _preload().then((_) {
      _isPreloaded = true;
      notifyListeners();
    });
  }

  Future<void> _preload() async {
    _prefs = await SharedPreferences.getInstance();
    _cache = {};
    for (final item in Settings.values) {
      if (item.preload) {
        item.triggerOnChange(get(item));
      }
    }
  }

  T get<T>(Settings<T> item) {
    return _readFromPrefs(item);
  }

  T _readFromPrefs<T>(Settings<T> item) {
    final key = item.name;

    if (_cache == null) {
      return item.defaultValue;
    }
    if (_cache!.containsKey(item)) {
      return _cache![item] as T;
    }

    switch (item.type) {
      case const (bool):
        return (_prefs.getBool(key) ?? item.defaultValue) as T;
      case const (int):
        return (_prefs.getInt(key) ?? item.defaultValue) as T;
      case const (double):
        return (_prefs.getDouble(key) ?? item.defaultValue) as T;
      case const (String):
        return (_prefs.getString(key) ?? item.defaultValue) as T;
      default:
        final storedValue = _prefs.getString(key);
        if (storedValue == null) {
          return item.defaultValue;
        }
        if (item.isEnum) {
          final options = item.options ?? [];
          final newEnum = (options as List<Enum>)
              .firstWhereOrNull((e) => e.name == storedValue);
          if (newEnum == null) {
            return item.options!.first; // default value
          } else {
            return newEnum as T;
          }
        } else {
          if (item.convertFrom != null) {
            return item.convertFrom!(storedValue);
          } else {
            throw ArgumentError(
                "Type ${item.type} is not a parsable type, please provide convertFrom function for conversion");
          }
        }
    }
  }

  void set<T>(Settings<T> item, T newValue) {
    final saved = _saveToPrefs(item, newValue);

    if (saved) {
      item.triggerOnChange(newValue);
      notifyListeners();
    }
  }

  bool _saveToPrefs<T>(Settings<T> item, T newValue) {
    final key = item.name;

    if (_cache != null) {
      _cache![item] = newValue;
    }

    switch (item.type) {
      case const (bool):
        _prefs.setBool(key, (newValue ?? item.defaultValue) as bool);
        return true;
      case const (int):
        _prefs.setInt(key, (newValue ?? item.defaultValue) as int);
        return true;
      case const (double):
        _prefs.setDouble(key, (newValue ?? item.defaultValue) as double);
        return true;
      case const (String):
        _prefs.setString(key, (newValue ?? item.defaultValue) as String);
        return true;
      default:
        if (item.isEnum) {
          final options = item.options ?? [];
          final newEnum =
              options.firstWhereOrNull((e) => e == newValue) as Enum;
          _prefs.setString(key, newEnum.name);
          return true;
        } else {
          if (item.convertTo != null) {
            _prefs.setString(key, item.convertTo!(newValue));
            return true;
          } else {
            throw ArgumentError(
                "Type ${item.type} is not a parsable type, please provide convertTo function for conversion");
          }
        }
    }
    return false;
  }

  void toggle<T>(Settings<T> item) {
    if (item.type == bool) {
      set(item, !get(item as Settings<bool>));
    } else {
      if (item.options == null) {
        throw ArgumentError('No options to toggle for ${item.name}');
      }
      final options = item.options!;
      final currentValue = get(item);

      set(item, options.toggle(currentValue));
    }
  }

  bool get isPreloaded => _isPreloaded;

  @protected
  void broadcast() {
    notifyListeners();
  }
}

class ColorSerializer {
  static Color from(String rawValue) {
    return Color(int.parse(rawValue, radix: 16));
  }

  static String to(Color color) {
    return (color).value.toRadixString(16);
  }
}
