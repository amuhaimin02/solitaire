import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/shared_preferences.dart';
import '../services/system_orientation.dart';

part 'settings.g.dart';

@riverpod
class SettingsScreenOrientation extends _$SettingsScreenOrientation
    with SharedPreferencesProviderMixin {
  @override
  final String key = 'settings_screen_orientation';

  @override
  final ScreenOrientation defaultValue = ScreenOrientation.auto;

  @override
  List<ScreenOrientation>? get options => ScreenOrientation.values;

  @override
  ScreenOrientation build() => get();
}

@riverpod
class SettingsShowLastMove extends _$SettingsShowLastMove
    with SharedPreferencesProviderMixin {
  @override
  final String key = 'settings_show_last_moves';

  @override
  final bool defaultValue = true;

  @override
  bool build() => get();
}

@riverpod
class SettingsShowScore extends _$SettingsShowScore
    with SharedPreferencesProviderMixin {
  @override
  final String key = 'settings_show_score';

  @override
  final bool defaultValue = true;

  @override
  bool build() => get();
}

@riverpod
class SettingsShowMoveCount extends _$SettingsShowMoveCount
    with SharedPreferencesProviderMixin {
  @override
  final String key = 'settings_show_move_count';

  @override
  final bool defaultValue = true;

  @override
  bool build() => get();
}

@riverpod
class SettingsShowPlayTime extends _$SettingsShowPlayTime
    with SharedPreferencesProviderMixin {
  @override
  final String key = 'settings_show_play_time';

  @override
  final bool defaultValue = true;

  @override
  bool build() => get();
}

@riverpod
class SettingsUseOneTapMove extends _$SettingsUseOneTapMove
    with SharedPreferencesProviderMixin {
  @override
  final String key = 'settings_use_one_tap_move';

  @override
  final bool defaultValue = true;

  @override
  bool build() => get();
}

@riverpod
class SettingsUseAutoPremove extends _$SettingsUseAutoPremove
    with SharedPreferencesProviderMixin {
  @override
  final String key = 'settings_use_auto_premove';

  @override
  final bool defaultValue = true;

  @override
  bool build() => get();
}

@riverpod
class SettingsShowAutoSolveButton extends _$SettingsShowAutoSolveButton
    with SharedPreferencesProviderMixin {
  @override
  final String key = 'settings_show_auto_solve_button';

  @override
  final bool defaultValue = true;

  @override
  bool build() => get();
}
