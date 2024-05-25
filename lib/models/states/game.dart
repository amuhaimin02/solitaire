import 'package:freezed_annotation/freezed_annotation.dart';

import '../action.dart';
import '../game/solitaire.dart';
import '../play_table.dart';

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
    this.table,
    this.action,
  );

  final PlayTable table;
  final Action action;
}

enum UserActionOptions { undoMultiple, redoMultiple }
