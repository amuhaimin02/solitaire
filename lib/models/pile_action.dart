import 'package:collection/collection.dart';
import 'package:xrandom/xrandom.dart';

import '../services/card_shuffler.dart';
import 'action.dart';
import 'card.dart';
import 'card_list.dart';
import 'pile.dart';
import 'pile_check.dart';
import 'play_data.dart';
import 'play_table.dart';

abstract class PileAction {
  const PileAction();

  PileActionResult action(Pile pile, PlayTable table, GameMetadata metadata);

  static PileActionResult run(List<PileAction>? actions, Pile pile,
      PlayTable table, GameMetadata metadata) {
    if (actions == null) {
      return const PileActionNoChange();
    }

    Move? move;
    int? score;

    for (final item in actions) {
      final result = item.action(pile, table, metadata);
      switch (result) {
        case (PileActionSuccess()):
          if (result.move != null) {
            if (move != null) {
              throw StateError('Move is already assigned');
            }
            move = result.move;
          }
          table = result.table;
          if (result.scoreGained != null) {
            score = (score ?? 0) + result.scoreGained!;
          }
        case PileActionNoChange():
      }
    }

    return PileActionSuccess(table: table, move: move, scoreGained: score);
  }

  static PileActionResult proceed(PileActionResult pastResult,
      List<PileAction>? actions, Pile pile, GameMetadata metadata) {
    if (pastResult is! PileActionSuccess) {
      return pastResult;
    }
    PlayTable table = pastResult.table;
    int? scoreGained = pastResult.scoreGained;
    Move? move = pastResult.move;

    final currentResult = PileAction.run(actions, pile, table, metadata);

    if (currentResult is PileActionSuccess) {
      table = currentResult.table;

      if (currentResult.move != null) {
        if (move != null) {
          throw StateError('Move is already assigned');
        }
        move = currentResult.move;
      }

      if (currentResult.scoreGained != null) {
        scoreGained = (scoreGained ?? 0) + currentResult.scoreGained!;
      }
    }
    return PileActionSuccess(
      table: table,
      scoreGained: scoreGained,
      move: move,
    );
  }
}

sealed class PileActionResult {
  const PileActionResult();
}

class PileActionSuccess extends PileActionResult {
  const PileActionSuccess({required this.table, this.move, this.scoreGained});

  final PlayTable table;
  final Move? move;
  final int? scoreGained;
}

class PileActionNoChange extends PileActionResult {
  const PileActionNoChange();
}

class If extends PileAction {
  If({
    required this.conditions,
    required this.ifTrue,
    this.ifFalse,
  });

  final List<PileCheck> conditions;
  final List<PileAction> ifTrue;
  final List<PileAction>? ifFalse;

  @override
  PileActionResult action(Pile pile, PlayTable table, GameMetadata metadata) {
    // TODO: Where to obtain the remaining param?
    if (PileCheck.checkAll(conditions, pile, null, [], table)) {
      return PileAction.run(ifTrue, pile, table, metadata);
    } else {
      if (ifFalse != null) {
        return PileAction.run(ifFalse, pile, table, metadata);
      } else {
        return const PileActionNoChange();
      }
    }
  }
}

// -------------------------------------------------------

class SetupNewDeck extends PileAction {
  const SetupNewDeck({this.count = 1});

  final int count;

  @override
  PileActionResult action(Pile pile, PlayTable table, GameMetadata metadata) {
    final existingCards = table.get(pile);
    final newCards = const CardShuffler()
        .generateShuffledDeck(Xrandom(metadata.randomSeed.hashCode));
    return PileActionSuccess(
      table: table.modify(pile, [...existingCards, ...newCards]),
    );
  }
}

class FlipAllCardsFaceUp extends PileAction {
  const FlipAllCardsFaceUp();

  @override
  PileActionResult action(Pile pile, PlayTable table, GameMetadata metadata) {
    return PileActionSuccess(
      table: table.modify(pile, table.get(pile).allFaceUp),
    );
  }
}

class FlipAllCardsFaceDown extends PileAction {
  const FlipAllCardsFaceDown();

  @override
  PileActionResult action(Pile pile, PlayTable table, GameMetadata metadata) {
    return PileActionSuccess(
      table: table.modify(pile, table.get(pile).allFaceDown),
    );
  }
}

class FlipTopmostCardFaceUp extends PileAction {
  const FlipTopmostCardFaceUp();

  @override
  PileActionResult action(Pile pile, PlayTable table, GameMetadata metadata) {
    final cardsOnPile = table.get(pile);
    return PileActionSuccess(
      table: table.modify(pile, [
        ...cardsOnPile.slice(0, cardsOnPile.length - 1),
        cardsOnPile.last.faceUp()
      ]),
    );
  }
}

class PickCardsFrom extends PileAction {
  const PickCardsFrom(this.fromPile, {required this.count});

  final Pile fromPile;

  final int count;

  @override
  PileActionResult action(Pile pile, PlayTable table, GameMetadata metadata) {
    final cardsFromPile = table.get(fromPile);
    final List<PlayCard> cardsToPick, remainingCards;
    if (cardsFromPile.length >= count) {
      cardsToPick = cardsFromPile.slice(
          cardsFromPile.length - count, cardsFromPile.length);
      remainingCards = cardsFromPile.slice(0, cardsFromPile.length - count);
    } else {
      cardsToPick = cardsFromPile;
      remainingCards = [];
    }

    return PileActionSuccess(
      table: table.modifyMultiple({
        fromPile: remainingCards,
        pile: cardsToPick,
      }),
    );
  }
}

class MoveNormally extends PileAction {
  const MoveNormally(
      {required this.from, required this.to, required this.cards});
  final Pile from;
  final Pile to;
  final List<PlayCard> cards;

  @override
  PileActionResult action(Pile pile, PlayTable table, GameMetadata metadata) {
    final cardsInHand = cards;
    final cardsOnTable = table.get(from);

    // Check and remove cards from source pile to hand
    final (remainingCards, cardsToPickUp) =
        cardsOnTable.splitLast(cardsInHand.length);

    // Check whether card picked is similar to what is on hand
    // if (!const ListEquality().equals(cardsToPickUp, cardsInHand)) {
    //   throw StateError("Cards picked up and in hand is not the same");
    // }

    // Move all cards on hand to target pile
    return PileActionSuccess(
      table: table.modifyMultiple({
        from: remainingCards,
        to: [...table.get(to), ...cardsToPickUp]
      }),
      move: Move(cardsToPickUp, from, to),
      scoreGained: 1,
    );
  }
}

class DrawCardsFromTop extends PileAction {
  const DrawCardsFromTop({
    required this.from,
    required this.to,
    required this.count,
  });
  final Pile from;
  final Pile to;
  final int count;

  @override
  PileActionResult action(Pile pile, PlayTable table, GameMetadata metadata) {
    final cardsOnTable = table.get(from);

    // Check and remove cards from source pile to hand
    final (remainingCards, cardsToPickUp) = cardsOnTable.splitLast(count);

    // Check whether card picked is similar to what is on hand
    // if (!const ListEquality().equals(cardsToPickUp, cardsInHand)) {
    //   throw StateError("Cards picked up and in hand is not the same");
    // }

    // Move all cards on hand to target pile
    return PileActionSuccess(
      table: table.modifyMultiple({
        from: remainingCards,
        to: [...table.get(to), ...cardsToPickUp]
      }),
      move: Move(cardsToPickUp, from, to),
    );
  }
}

class Redeal extends PileAction {
  const Redeal({required this.takeFrom});
  final Pile takeFrom;

  @override
  PileActionResult action(Pile pile, PlayTable table, GameMetadata metadata) {
    return PileActionSuccess(
      table: table.modifyMultiple({
        takeFrom: [],
        pile: [
          ...table.get(pile),
          ...table.get(takeFrom).reversed,
        ].allFaceDown,
      }),
      move: Move([], takeFrom, pile),
    );
  }
}

class FlipTopCardFaceUp extends PileAction {
  const FlipTopCardFaceUp();

  @override
  PileActionResult action(Pile pile, PlayTable table, GameMetadata metadata) {
    final cardsOnPile = table.get(pile);

    if (cardsOnPile.isEmpty || cardsOnPile.last.isFacingUp) {
      return const PileActionNoChange();
    }

    return PileActionSuccess(
      table: table.modify(
        pile,
        [
          ...cardsOnPile.slice(0, cardsOnPile.length - 1),
          cardsOnPile.last.faceUp()
        ],
      ),
    );
  }
}

class ObtainScore extends PileAction {
  const ObtainScore({required this.score});

  final int score;

  @override
  PileActionResult action(Pile pile, PlayTable table, GameMetadata metadata) {
    return PileActionSuccess(table: table, scoreGained: 100);
  }
}
