import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/game_status.dart';
import '../models/pile.dart';
import '../services/all.dart';
import 'game_logic.dart';
import 'game_move_history.dart';
import 'settings.dart';

part 'feedback.g.dart';

@Riverpod(keepAlive: true)
class FeedbackIsFirstLaunch extends _$FeedbackIsFirstLaunch {
  @override
  bool build() {
    ref.listenSelf((_, isFirstLaunch) {
      if (isFirstLaunch) {
        Future.microtask(() => state = false);
      }
    });
    return true;
  }
}

@riverpod
void feedback(FeedbackRef ref) {
  final lastMove = ref.watch(lastMoveProvider);
  final gameStatus = ref.watch(gameControllerProvider);
  final moveType = ref.watch(currentMoveTypeProvider);

  if (gameStatus == GameStatus.started) {
    if (ref.read(feedbackIsFirstLaunchProvider)) {
      return;
    }
  }

  srv<Logger>().d('Status: $gameStatus, Feedback: $lastMove, Move: $moveType');

  final target = lastMove?.action.move?.to;

  if (ref.read(settingsEnableVibrationProvider)) {
    switch (target) {
      case Stock() || Foundation():
        HapticFeedback.heavyImpact();
      case Tableau() || Grid():
        HapticFeedback.mediumImpact();
      case Waste() || Reserve():
        HapticFeedback.lightImpact();
      case null:
    }
  }
}
