import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/action.dart';
import '../models/card_distribute_animation.dart';
import '../models/game_status.dart';
import '../models/pile.dart';
import '../models/play_table.dart';
import '../services/all.dart';
import '../services/sound_effect.dart';
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
  final vibrationEnabled = ref.watch(settingsEnableVibrationProvider);
  final soundsEnabled = ref.watch(settingsEnableSoundsProvider);

  if (gameStatus == GameStatus.started) {
    if (ref.read(feedbackIsFirstLaunchProvider)) {
      return;
    }
  }

  svc<Logger>().d('Status: $gameStatus, Feedback: $lastMove, Move: $moveType');

  if (vibrationEnabled) {
    final target = lastMove?.action.move?.to;

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

  if (soundsEnabled) {
    final soundEffect = svc<SoundEffectManager>();
    switch (gameStatus) {
      case GameStatus.ready:
      // noop
      case GameStatus.initializing:
        soundEffect.play(SoundEffect.cardFlip2);
      case GameStatus.preparing:
        final keyframes = _computeCardDistributionKeyframes(lastMove!.table);
        for (final duration in keyframes) {
          Future.delayed(
              duration, () => soundEffect.play(SoundEffect.cardMove2));
        }
      case GameStatus.started || GameStatus.autoSolving:
        switch (lastMove?.action) {
          case Move(:final to):
            if (to is Foundation) {
              soundEffect.play(SoundEffect.cardMove2);
            } else {
              soundEffect.play(SoundEffect.cardMove1);
            }
          case Draw():
            soundEffect.play(SoundEffect.cardFlip1);
          case Deal():
            soundEffect.play(SoundEffect.cardFlip2);
          default:
          // noop
        }
      case GameStatus.finished:
        soundEffect.play(SoundEffect.balloonPop);
    }
  }
}

List<Duration> _computeCardDistributionKeyframes(PlayTable table) {
  const delay = CardDistributeAnimationDelay();
  final keyframes = <Duration>{};

  for (final pile in table.allPiles()) {
    final cardsOnPile = table.get(pile);
    if (cardsOnPile.isNotEmpty) {
      for (int i = 0; i < cardsOnPile.length; i++) {
        final duration = delay.compute(pile, i);
        keyframes.add(duration);
      }
    }
  }

  return keyframes.toList();
}
