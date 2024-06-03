import 'package:collection/collection.dart';
import 'package:xrandom/xrandom.dart';

import '../services/card_shuffler.dart';
import '../utils/prng.dart';
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
  const If({
    required this.conditions,
    this.ifTrue,
    this.ifFalse,
  });

  final List<PileCheck> conditions;
  final List<PileAction>? ifTrue;
  final List<PileAction>? ifFalse;

  @override
  PileActionResult action(Pile pile, PlayTable table, GameMetadata metadata) {
    // TODO: Where to obtain the remaining param?
    final condition = PileCheck.checkAll(conditions, pile, null, [], table);
    if (condition && ifTrue != null) {
      return PileAction.run(ifTrue, pile, table, metadata);
    } else if (!condition && ifFalse != null) {
      return PileAction.run(ifFalse, pile, table, metadata);
    } else {
      return const PileActionNoChange();
    }
  }
}

// -------------------------------------------------------

class SetupNewDeck extends PileAction {
  const SetupNewDeck({this.count = 1, this.onlySuit});

  final int count;

  final List<Suit>? onlySuit;

  @override
  PileActionResult action(Pile pile, PlayTable table, GameMetadata metadata) {
    final existingCards = table.get(pile);

    final newCards = const CardShuffler().generateShuffledDeck(
      numberOfDecks: count,
      CustomPRNG.create(metadata.randomSeed),
      criteria:
          onlySuit != null ? (card) => onlySuit!.contains(card.suit) : null,
    );

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

class PickCardsFrom extends PileAction {
  const PickCardsFrom(this.fromPile, {required this.count});

  final Pile fromPile;

  final int count;

  @override
  PileActionResult action(Pile pile, PlayTable table, GameMetadata metadata) {
    final cardsFromPile = table.get(fromPile);
    final (remainingCards, cardsToPick) = cardsFromPile.splitLast(count);

    return PileActionSuccess(
      table: table.modifyMultiple({
        fromPile: remainingCards,
        pile: cardsToPick,
      }),
    );
  }
}

class MoveNormally extends PileAction {
  const MoveNormally({required this.to, required this.cards});
  final Pile to;
  final List<PlayCard> cards;

  @override
  PileActionResult action(Pile pile, PlayTable table, GameMetadata metadata) {
    final cardsInHand = cards;
    final cardsOnTable = table.get(pile);

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
        pile: remainingCards,
        to: [...table.get(to), ...cardsToPickUp]
      }),
      move: Move(cardsToPickUp, pile, to),
      scoreGained: 1,
    );
  }
}

class DrawFromTop extends PileAction {
  const DrawFromTop({
    required this.to,
    required this.count,
  });
  final Pile to;
  final int count;

  @override
  PileActionResult action(Pile pile, PlayTable table, GameMetadata metadata) {
    final cardsOnTable = table.get(pile);

    // Check and remove cards from source pile to hand
    final (remainingCards, cardsToPickUp) = cardsOnTable.splitLast(count);

    // Check whether card picked is similar to what is on hand
    // if (!const ListEquality().equals(cardsToPickUp, cardsInHand)) {
    //   throw StateError("Cards picked up and in hand is not the same");
    // }

    // Move all cards on hand to target pile
    return PileActionSuccess(
      table: table.modifyMultiple({
        pile: remainingCards,
        to: [...table.get(to), ...cardsToPickUp.allFaceUp]
      }),
      move: Move(cardsToPickUp, pile, to),
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

class DistributeEquallyToAll<T extends Pile> extends PileAction {
  const DistributeEquallyToAll({required this.count});

  final int count;

  @override
  PileActionResult action(Pile pile, PlayTable table, GameMetadata metadata) {
    final allPilesOfType = table.allPilesOfType<T>().toList();
    final (remainingCards, cardsToDistribute) =
        table.get(pile).splitLast(allPilesOfType.length);

    // TODO: Support count more than 1
    return PileActionSuccess(
      table: table.modifyMultiple({
        pile: remainingCards,
        for (final (i, p) in allPilesOfType.indexed)
          p: [...table.get(p), cardsToDistribute[i].faceUp()]
      }),
      // TODO: Change this
      move: const Move([], Draw(), Draw()),
    );
  }
}

class SendToAnyEmptyPile<T extends Pile> extends PileAction {
  const SendToAnyEmptyPile({required this.count});

  final int count;

  @override
  PileActionResult action(Pile pile, PlayTable table, GameMetadata metadata) {
    final allPilesOfType = table.allPilesOfType<T>().toList();

    final (remainingCards, cardsToSend) = table.get(pile).splitLast(count);

    for (final targetPile in allPilesOfType) {
      final cardsOnPile = table.get(targetPile);

      if (cardsOnPile.isEmpty) {
        return PileActionSuccess(
          table: table.modifyMultiple({
            pile: remainingCards,
            targetPile: [...cardsOnPile, ...cardsToSend]
          }),
        );
      }
    }

    return const PileActionNoChange();
  }
}
