import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/pile.dart';
import 'game_logic.dart';
import 'game_move_history.dart';
import 'settings.dart';

part 'feedback.g.dart';

@riverpod
void feedback(FeedbackRef ref) {
  final lastAction = ref.watch(currentActionProvider);
  final gameStatus = ref.watch(gameControllerProvider);
  print('Status: $gameStatus, Feedback: $lastAction');

  final target = lastAction?.move?.to;

  if (ref.read(settingsEnableVibrationProvider)) {
    switch (target) {
      case Draw():
        HapticFeedback.heavyImpact();
      case Discard():
        HapticFeedback.lightImpact();
      case Foundation():
        HapticFeedback.heavyImpact();
      case Tableau():
        HapticFeedback.mediumImpact();
      case Reserve():
        HapticFeedback.lightImpact();
      case null:
    }
  }
}
