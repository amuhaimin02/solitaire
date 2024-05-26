import 'package:freezed_annotation/freezed_annotation.dart';

import 'game/solitaire.dart';
import 'move_record.dart';

part 'play_data.freezed.dart';

@freezed
class GameMetadata with _$GameMetadata {
  factory GameMetadata({
    required SolitaireGame rules,
    required DateTime startedTime,
    required String randomSeed,
  }) = _GameMetadata;
}

@freezed
class GameState with _$GameState {
  factory GameState({
    required int moves,
    required int score,
    required Duration playTime,
  }) = _GameState;
}

@freezed
class GameData with _$GameData {
  factory GameData({
    required GameMetadata metadata,
    required GameState state,
    required List<MoveRecord> history,
  }) = _GameData;
}
