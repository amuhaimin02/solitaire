import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class GameTheme extends ChangeNotifier {
  ThemeMode _currentThemeMode = ThemeMode.system;

  MaterialColor? _presetColor;

  static const colorPalette = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  void changeMode(ThemeMode newMode) {
    _currentThemeMode = newMode;
    notifyListeners();
  }

  void toggleUsePresetColors(bool turnOn) {
    if (turnOn) {
      _presetColor = _pickRandomColorFromPalette();
    } else {
      _presetColor = null;
    }

    notifyListeners();
  }

  void changePresetColor() {
    if (_presetColor != null) {
      MaterialColor newColor;
      do {
        newColor = _pickRandomColorFromPalette();
      } while (newColor == _presetColor);
      _presetColor = newColor;

      notifyListeners();
    }
  }

  MaterialColor _pickRandomColorFromPalette() {
    return colorPalette.sample(1).single;
  }

  ThemeMode get currentMode => _currentThemeMode;

  bool get usingRandomColors => _presetColor != null;

  MaterialColor? get currentPresetColor => _presetColor;
}
