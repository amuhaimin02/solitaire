import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/serializer.dart';

part 'shared_preferences.g.dart';

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

  Serializer? get serializer => null;

  T get() {
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
      throw ArgumentError('toggling is not supported for type $T');
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
                'Please provide options list for enum settings');
          }
          final storedEnum = (opts as List<Enum>)
              .firstWhereOrNull((e) => e.name == storedValue);
          return storedEnum as T?;
        } else if (serializer != null) {
          return serializer!.deserialize(storedValue);
        } else {
          throw ArgumentError(
              'Type $T is not supported. Please provide a serializer');
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
                'Please provide options list for enum settings');
          }
          final valueEnum = (opts as List<Enum>).firstWhere((e) => e == value);
          prefs.setString(key, valueEnum.name);
        } else if (serializer != null) {
          prefs.setString(key, serializer!.serialize(value));
        } else {
          throw ArgumentError(
              'Type $T is not supported. Please provide a serializer');
        }
    }
    return value;
  }
}
