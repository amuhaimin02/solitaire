import 'package:freezed_annotation/freezed_annotation.dart';

import '../utils/types.dart';
import 'action.dart';
import 'card.dart';
import 'move_record.dart';
import 'pile.dart';
import 'play_table.dart';

part 'move_attempt.freezed.dart';

typedef MoveAttemptTest = bool Function(
    Pile from, Pile to, MoveAttemptArgs args);

class MoveAttempt<From extends Pile, To extends Pile> {
  const MoveAttempt({this.cardLength, this.onlyIf});

  final int? cardLength;

  final MoveAttemptTest? onlyIf;

  Iterable<MoveIntent> attemptMoves(MoveAttemptArgs args) sync* {
    final sourcePiles = args.table.allPilesOfType<From>();
    final targetPiles = args.table.allPilesOfType<To>();

    for (final from in sourcePiles) {
      PlayCard? cardToMove;

      if (cardLength != null) {
        final cardsOnPile = args.table.get(from);

        if (cardsOnPile.isNotEmpty) {
          cardToMove = cardsOnPile.length > cardLength!
              ? cardsOnPile[cardsOnPile.length - cardLength!]
              : cardsOnPile.first;
        }
      }

      for (final to in targetPiles) {
        if (onlyIf?.call(from, to, args) == false) {
          continue;
        }

        yield MoveIntent(from, to, cardToMove);
      }
    }
  }

  static Iterable<MoveIntent> getAttempts(
    List<MoveAttempt> attempts,
    MoveAttemptArgs args,
  ) sync* {
    for (final attempt in attempts) {
      yield* attempt.attemptMoves(args);
    }
  }
}

class MoveCompletedPairs<From extends Pile, To extends Pile>
    extends MoveAttempt<From, To> {
  const MoveCompletedPairs({super.onlyIf}) : super(cardLength: 2);

  @override
  Iterable<MoveIntent> attemptMoves(MoveAttemptArgs args) sync* {
    final sourcePiles = args.table.allPilesOfType<From>();
    final targetPiles = args.table.allPilesOfType<To>();

    for (final from in sourcePiles) {
      final cardsOnPile = args.table.get(from);
      if (cardsOnPile.length >= 2) {
        PlayCard? cardToMove;
        cardToMove = cardsOnPile[cardsOnPile.length - 2];

        for (final to in targetPiles) {
          if (onlyIf?.call(from, to, args) == false) {
            continue;
          }
          yield MoveIntent(from, to, cardToMove);
        }
      }
    }
  }
}

class MoveAttemptTo<To extends Pile> {
  const MoveAttemptTo({
    this.onlyIf,
    this.prioritizeNonEmptySpaces = false,
    this.prioritizeShorterStacks = false,
  });

  final MoveAttemptTest? onlyIf;
  final bool prioritizeNonEmptySpaces;
  final bool prioritizeShorterStacks;

  Iterable<MoveIntent> attemptMoves(MoveAttemptArgs args) sync* {
    Iterable<To> pileIterator = args.table.allPilesOfType<To>();
    final from = args.from!;

    if (args.from.runtimeType == To) {
      pileIterator = pileIterator.roll(from: from).skip(1);
    }
    if (prioritizeNonEmptySpaces || prioritizeShorterStacks) {
      pileIterator = pileIterator.toList().sortedByPriority((pile) {
        final cardsOnPile = args.table.get(pile);

        if (prioritizeNonEmptySpaces && cardsOnPile.isEmpty) {
          return 0;
        }
        if (prioritizeShorterStacks) {
          return intMaxValue - cardsOnPile.length;
        } else {
          return 1;
        }
      });
    }
    for (final to in pileIterator) {
      if (onlyIf?.call(from, to, args) == false) {
        continue;
      }

      yield MoveIntent(from, to, args.card);
    }
  }

  static Iterable<MoveIntent> getAttempts(
      List<MoveAttemptTo> attempts, MoveAttemptArgs args) sync* {
    for (final attempt in attempts) {
      yield* attempt.attemptMoves(args);
    }
  }
}

@freezed
class MoveAttemptArgs with _$MoveAttemptArgs {
  const factory MoveAttemptArgs({
    required PlayTable table,
    required MoveState? moveState,
    required Action? lastAction,
    PlayCard? card,
    Pile? from,
  }) = _MoveAttemptArgs;
}
