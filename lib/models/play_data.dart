import 'package:freezed_annotation/freezed_annotation.dart';

import 'game/solitaire.dart';
import 'move_record.dart';

part 'play_data.freezed.dart';

@freezed
class GameMetadata with _$GameMetadata {
  factory GameMetadata({
    required SolitaireGame kind,
    required DateTime startedTime,
    required String seed,
  }) = _GameMetadata;
}

@freezed
class GameState with _$GameState {
  factory GameState({
    required Duration playTime,
    required int moveCursor,
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
