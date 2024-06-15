import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'shared_preferences.dart';
import '../services/system_window.dart';

part 'settings.g.dart';

@riverpod
class SettingsLastPlayedGame extends _$SettingsLastPlayedGame
    with SharedPreferencesProviderMixin {
  @override
  final String key = 'settings_last_played_game';

  @override
  String get defaultValue => '';

  @override
  String build() => get();
}

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
class SettingsShowStatusBar extends _$SettingsShowStatusBar
    with SharedPreferencesProviderMixin {
  @override
  final String key = 'settings_show_status_bar';

  @override
  final bool defaultValue = true;

  @override
  bool build() => get();
}

// @riverpod
// class SettingsShowLastMove extends _$SettingsShowLastMove
//     with SharedPreferencesProviderMixin {
//   @override
//   final String key = 'settings_show_last_moves';
//
//   @override
//   final bool defaultValue = true;
//
//   @override
//   bool build() => get();
// }

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

@riverpod
class SettingsEnableSounds extends _$SettingsEnableSounds
    with SharedPreferencesProviderMixin {
  @override
  final String key = 'settings_enable_sounds';

  @override
  final bool defaultValue = true;

  @override
  bool build() => get();
}

@riverpod
class SettingsEnableVibration extends _$SettingsEnableVibration
    with SharedPreferencesProviderMixin {
  @override
  final String key = 'settings_enable_vibration';

  @override
  final bool defaultValue = true;

  @override
  bool build() => get();
}
