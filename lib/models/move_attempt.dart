import '../utils/types.dart';
import 'action.dart';
import 'card.dart';
import 'pile.dart';
import 'play_table.dart';

typedef MoveAttemptTest = bool Function(PlayTable table, Pile from, Pile to);

class MoveAttempt<From extends Pile, To extends Pile> {
  const MoveAttempt({this.cardLength, this.onlyIf});

  final int? cardLength;

  final MoveAttemptTest? onlyIf;

  Iterable<MoveIntent> attemptMoves(PlayTable table) sync* {
    for (final from in table.allPilesOfType<From>()) {
      PlayCard? cardToMove;

      if (cardLength != null) {
        final cardsOnPile = table.get(from);

        if (cardsOnPile.isNotEmpty) {
          cardToMove = cardsOnPile.length > cardLength!
              ? cardsOnPile[cardsOnPile.length - cardLength!]
              : cardsOnPile.first;
        }
      }

      for (final to in table.allPilesOfType<To>()) {
        if (onlyIf?.call(table, from, to) == false) {
          continue;
        }

        yield MoveIntent(from, to, cardToMove);
      }
    }
  }

  static Iterable<MoveIntent> getAttempts(
      List<MoveAttempt> attempts, PlayTable table) sync* {
    for (final attempt in attempts) {
      yield* attempt.attemptMoves(table);
    }
  }
}

class MoveAttemptTo<To extends Pile> {
  const MoveAttemptTo({
    this.onlyIf,
    this.roll = false,
    this.prioritizeNonEmptySpaces = false,
  });

  final MoveAttemptTest? onlyIf;
  final bool roll;
  final bool prioritizeNonEmptySpaces;

  Iterable<MoveIntent> attemptMoves(
      PlayTable table, PlayCard card, Pile from) sync* {
    Iterable<To> pileIterator = table.allPilesOfType<To>();

    if (roll && from.runtimeType == To) {
      pileIterator = pileIterator.roll(from: from).skip(1);
    }
    if (prioritizeNonEmptySpaces) {
      pileIterator = pileIterator.toList().sortedByPriority((pile) {
        return table.get(pile).isNotEmpty ? 1 : 0;
      });
    }
    for (final to in pileIterator) {
      if (onlyIf?.call(table, from, to) == false) {
        continue;
      }

      yield MoveIntent(from, to, card);
    }
  }

  static Iterable<MoveIntent> getAttempts(List<MoveAttemptTo> attempts,
      PlayTable table, PlayCard card, Pile from) sync* {
    for (final attempt in attempts) {
      yield* attempt.attemptMoves(table, card, from);
    }
  }
}
