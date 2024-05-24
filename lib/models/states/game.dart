import '../pile.dart';
import '../rules/rules.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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
  initializing,
  ready,
  preparing,
  started,
  autoSolving,
  ended,
  restarting
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
