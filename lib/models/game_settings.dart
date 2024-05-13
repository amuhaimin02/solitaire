import 'package:flutter/widgets.dart';

class SettingItem<T> {
  final GameSettings _settings;

  T _value;

  SettingItem(this._settings, this._value);

  void set(T newValue) {
    _value = newValue;
    _settings.broadcast();
  }

  T get current => _value;
}

class GameSettings with ChangeNotifier {
  late final autoMoveOnDraw = SettingItem(this, true);

  @protected
  void broadcast() {
    notifyListeners();
  }
}
