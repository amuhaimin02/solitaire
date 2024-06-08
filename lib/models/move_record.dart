import 'package:freezed_annotation/freezed_annotation.dart';

import 'action.dart';
import 'pile.dart';
import 'play_table.dart';

part 'move_record.freezed.dart';

@freezed
class MoveRecord with _$MoveRecord {
  factory MoveRecord({
    required Action action,
    required MoveState state,
    required PlayTable table,
  }) = _MoveRecord;
}

@freezed
class MoveState with _$MoveState {
  factory MoveState({
    required int moveNumber,
    required Map<Pile, int> recycleCounts,
    required int score,
  }) = _MoveState;
}
