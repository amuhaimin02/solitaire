import 'package:freezed_annotation/freezed_annotation.dart';

import '../pile.dart';
import '../rules/rules.dart';

part 'game.freezed.dart';

@freezed
class PlayData with _$PlayData {
  factory PlayData({
    required SolitaireGame rules,
    required DateTime startedTime,
    required String randomSeed,
  }) = _PlayData;
}

enum GameStatus {
  ready,
  initializing,
  preparing,
  started,
  autoSolving,
  finished,
}

class MoveRecord {
  MoveRecord(
    this.cards,
    this.action,
  );

  final PlayCards cards;
  final Action action;
}

enum UserAction { undoMultiple, redoMultiple }
