import 'package:freezed_annotation/freezed_annotation.dart';

import 'action.dart';
import 'play_data.dart';
import 'play_table.dart';

part 'move_record.freezed.dart';

@freezed
class MoveRecord with _$MoveRecord {
  factory MoveRecord({
    required Action action,
    required PlayTable table,
    required GameState state,
  }) = _MoveRecord;
}
