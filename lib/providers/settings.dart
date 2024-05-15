import 'package:flutter/widgets.dart';

import '../utils/lists.dart';
import '../utils/system_orientation.dart';

class Settings with ChangeNotifier {
  late final autoMoveOnDraw = SettingItem(this, defaultValue: false);

  late final showDebugPanel = SettingItem(this, defaultValue: false);

  late final showMoveHighlight = SettingItem(this, defaultValue: false);

  late final screenOrientation = SettingItem(
    this,
    defaultValue: SystemOrientation.auto,
    options: SystemOrientation.values,
    onChange: SystemOrientationManager.change,
  );

  @protected
  void broadcast() {
    notifyListeners();
  }
}

class SettingItem<T> {
  final Settings _settings;

  T _value;

  List<T>? options;

  void Function(T value)? onChange;

  SettingItem(
    this._settings, {
    required T defaultValue,
    this.options,
    this.onChange,
  }) : _value = defaultValue {
    onChange?.call(_value);
  }

  void set(T newValue) {
    _value = newValue;
    onChange?.call(_value);
    _settings.broadcast();
  }

  T get() => _value;

  T call([T? newValue]) {
    if (newValue != null) {
      set(newValue);
      return _value;
    } else {
      return _value;
    }
  }

  void toggle() {
    if (options != null) {
      set(options!.toggle(_value));
    }

    if (T == bool) {
      set(!(_value as bool) as T);
    }
  }
}
