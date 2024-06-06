import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/move_record.dart';

part 'game_move_history.g.dart';

@riverpod
class MoveCursor extends _$MoveCursor {
  @override
  int build() => 0;

  void reset() => state = 0;

  void set(int value) => state = value;
}

@riverpod
class MoveRecordList extends _$MoveRecordList {
  @override
  List<MoveRecord> build() => [];

  void add(MoveRecord record) {
    state = [...state, record];
    ref.watch(moveCursorProvider.notifier).set(state.length - 1);
  }
}

@riverpod
MoveRecord currentMove(CurrentMoveRef ref) {
  final list = ref.watch(moveRecordListProvider);
  final cursor = ref.watch(moveCursorProvider);
  return list[cursor];
}
