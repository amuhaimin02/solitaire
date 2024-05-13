import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class GameTheme extends ChangeNotifier {
  ThemeMode _currentThemeMode = ThemeMode.system;

  MaterialColor _presetColor = colorPalette.first;

  bool _usePresetColor = false;

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

  void toggleUsePresetColors() {
    _usePresetColor = !_usePresetColor;

    notifyListeners();
  }

  void changePresetColor() {
    _presetColor = colorPalette[
        (colorPalette.indexOf(_presetColor) + 1) % colorPalette.length];

    notifyListeners();
  }

  ThemeMode get currentMode => _currentThemeMode;

  bool get usingRandomColors => _usePresetColor;

  MaterialColor? get currentPresetColor => _presetColor;
}
