import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/pile.dart';
import 'game_logic.dart';
import 'settings.dart';

part 'feedback.g.dart';

@riverpod
void feedback(FeedbackRef ref) {
  final lastAction = ref.watch(lastActionProvider);
  print(lastAction);

  final target = lastAction.move?.to;

  if (ref.read(settingsEnableVibrationProvider)) {
    print('bzzz');
    switch (target) {
      case Draw():
        HapticFeedback.heavyImpact();
      case Discard():
        HapticFeedback.lightImpact();
      case Foundation():
        HapticFeedback.heavyImpact();
      case Tableau():
        HapticFeedback.mediumImpact();
      default:
    }
  }
}
