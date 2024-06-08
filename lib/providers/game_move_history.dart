import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/action.dart';
import '../models/move_record.dart';
import '../models/play_table.dart';

part 'game_move_history.g.dart';

enum MoveType { normal, undo, redo }

@riverpod
class MoveCursor extends _$MoveCursor {
  @override
  int build() => 0;

  int reset() => state = 0;

  int set(int value) => state = value;

  int shift() => ++state;

  int stepBack() => --state;
}

@riverpod
class MoveRecordList extends _$MoveRecordList {
  @override
  List<MoveRecord> build() => [];

  void set(List<MoveRecord> records) {
    state = records;
  }

  void add(MoveRecord record, {required int at}) {
    state = [...state.sublist(0, at), record];
  }

  void pruneLast({required int from}) {
    state = [...state.sublist(0, from)];
  }
}

@riverpod
class CurrentMoveType extends _$CurrentMoveType {
  @override
  MoveType build() {
    return MoveType.normal;
  }
}

@riverpod
MoveRecord? currentMove(CurrentMoveRef ref) {
  final list = ref.watch(moveRecordListProvider);
  final cursor = ref.watch(moveCursorProvider);
  if (list.isEmpty) {
    return null;
  }
  return list[cursor];
}

@riverpod
MoveRecord? lastMove(LastMoveRef ref) {
  final list = ref.watch(moveRecordListProvider);
  final cursor = ref.watch(moveCursorProvider);
  final isUndo = ref.watch(currentMoveTypeProvider) == MoveType.undo;
  if (list.isEmpty) {
    return null;
  } else if (isUndo) {
    return list[cursor + 1];
  } else {
    return list[cursor];
  }
}

@riverpod
PlayTable currentTable(CurrentTableRef ref) {
  return ref.watch(currentMoveProvider)?.table ?? PlayTable.empty();
}

@riverpod
Action? currentAction(CurrentActionRef ref) {
  return ref.watch(currentMoveProvider)?.action;
}

@riverpod
int? currentScore(CurrentScoreRef ref) {
  return ref.watch(currentMoveProvider)?.state.score;
}

@riverpod
int? currentMoveNumber(CurrentMoveNumberRef ref) {
  return ref.watch(currentMoveProvider)?.state.moveNumber;
}

@riverpod
class MoveHistory extends _$MoveHistory {
  @override
  void build() {}

  void createNew(PlayTable table, Action action) {
    ref.read(currentMoveTypeProvider.notifier).state = MoveType.normal;
    ref.read(moveCursorProvider.notifier).reset();
    ref.read(moveRecordListProvider.notifier).set([
      MoveRecord(
        action: action,
        state: MoveState(moveNumber: 0, score: 0),
        table: table,
      )
    ]);
  }

  void add(
    PlayTable table,
    Action action, {
    int score = 0,
    bool retainMoveCount = false,
  }) {
    final lastMove = ref.read(currentMoveProvider);
    final lastMoveNumber = lastMove?.state.moveNumber ?? 0;
    final lastScore = lastMove?.state.score ?? 0;
    final int newMoveNumber;

    if (action.countAsMove && !retainMoveCount) {
      newMoveNumber = lastMoveNumber + 1;
    } else {
      newMoveNumber = lastMoveNumber;
    }

    // Add to the point where move cursor is
    final newRecord = MoveRecord(
      action: action,
      state: MoveState(
        moveNumber: newMoveNumber,
        score: lastScore + score,
      ),
      table: table,
    );

    int cursor = ref.read(moveCursorProvider);

    ref.read(currentMoveTypeProvider.notifier).state = MoveType.normal;
    ref.read(moveRecordListProvider.notifier).add(newRecord, at: cursor + 1);
    ref.read(moveCursorProvider.notifier).shift();
  }

  bool canUndo() {
    final moves = ref.read(moveCursorProvider);
    return moves > 1;
  }

  bool canRedo() {
    final moves = ref.read(moveCursorProvider);
    return moves < ref.read(moveRecordListProvider).length - 1;
  }

  void undo() {
    if (canUndo()) {
      ref.read(currentMoveTypeProvider.notifier).state = MoveType.undo;
      ref.read(moveCursorProvider.notifier).stepBack();
    }
  }

  void redo() {
    if (canRedo()) {
      ref.read(currentMoveTypeProvider.notifier).state = MoveType.redo;
      ref.read(moveCursorProvider.notifier).shift();
    }
  }

  void restart() {
    ref.read(currentMoveTypeProvider.notifier).state = MoveType.normal;
    ref.read(moveCursorProvider.notifier).set(1);
    ref.read(moveRecordListProvider.notifier).pruneLast(from: 2);
  }

  void restore(int moveCursor, List<MoveRecord> records) {
    ref.read(currentMoveTypeProvider.notifier).state = MoveType.normal;
    ref.read(moveCursorProvider.notifier).set(moveCursor);
    ref.read(moveRecordListProvider.notifier).set(records);
  }
}
