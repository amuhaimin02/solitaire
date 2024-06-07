import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/pile.dart';
import 'game_logic.dart';
import 'game_move_history.dart';
import 'settings.dart';

part 'feedback.g.dart';

@riverpod
void feedback(FeedbackRef ref) {
  final lastMove = ref.watch(lastMoveProvider);
  final gameStatus = ref.watch(gameControllerProvider);
  final moveType = ref.watch(currentMoveTypeProvider);

  print('Status: $gameStatus, Feedback: $lastMove, Move: $moveType');

  final target = lastMove?.action.move?.to;

  if (ref.read(settingsEnableVibrationProvider)) {
    switch (target) {
      case Stock() || Foundation():
        HapticFeedback.heavyImpact();
      case Tableau():
        HapticFeedback.mediumImpact();
      case Waste() || Reserve():
        HapticFeedback.lightImpact();
      case null:
    }
  }
}
