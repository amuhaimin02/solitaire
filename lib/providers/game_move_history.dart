import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/action.dart';
import '../models/move_record.dart';
import '../models/pile.dart';
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
MoveRecord? nextMove(CurrentMoveRef ref) {
  final list = ref.watch(moveRecordListProvider);
  final cursor = ref.watch(moveCursorProvider);
  if (list.isEmpty || cursor > list.length - 1) {
    return null;
  }
  return list[cursor + 1];
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
        isAutoMove: true,
        action: action,
        state: MoveState(moveNumber: 0, score: 0, recycleCounts: {}),
        table: table,
      )
    ]);
  }

  void add(
    PlayTable table,
    Action action, {
    int score = 0,
    List<Pile>? recycledPiles,
    bool isAutoMove = false,
    bool skipMoveCount = false,
  }) {
    final lastMove = ref.read(currentMoveProvider);
    final lastMoveNumber = lastMove?.state.moveNumber ?? 0;
    final lastScore = lastMove?.state.score ?? 0;
    final lastRecycleCounts = lastMove?.state.recycleCounts ?? {};

    final int newMoveNumber;

    if (isAutoMove || skipMoveCount) {
      newMoveNumber = lastMoveNumber;
    } else {
      newMoveNumber = lastMoveNumber + 1;
    }

    final Map<Pile, int> newRecycleCounts;

    if (recycledPiles != null) {
      newRecycleCounts = {
        ...lastRecycleCounts,
        for (final pile in recycledPiles)
          pile: (lastRecycleCounts[pile] ?? 0) + 1
      };
    } else {
      newRecycleCounts = lastRecycleCounts;
    }

    // Add to the point where move cursor is
    final newRecord = MoveRecord(
      isAutoMove: isAutoMove,
      action: action,
      state: MoveState(
        moveNumber: newMoveNumber,
        recycleCounts: newRecycleCounts,
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
      // Skip auto moves
      MoveRecord? move;
      do {
        // Note: Checking move state before actually undoing
        move = ref.read(currentMoveProvider);
        ref.read(moveCursorProvider.notifier).stepBack();
      } while (move?.isAutoMove == true);
    }
  }

  void redo() {
    if (canRedo()) {
      ref.read(currentMoveTypeProvider.notifier).state = MoveType.redo;

      final moveLength = ref.read(moveRecordListProvider).length;

      // Skip auto moves
      MoveRecord? move;
      do {
        // Note: Checking move state after actually redoing
        final newCursor = ref.read(moveCursorProvider.notifier).shift();
        if (newCursor >= moveLength - 1) {
          break;
        }
        move = ref.read(nextMoveProvider);
      } while (move?.isAutoMove == true);
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
