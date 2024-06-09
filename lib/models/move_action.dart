import 'package:collection/collection.dart';

import '../services/card_shuffler.dart';
import '../utils/prng.dart';
import 'action.dart';
import 'card.dart';
import 'card_list.dart';
import 'move_check.dart';
import 'move_event.dart';
import 'move_record.dart';
import 'pile.dart';
import 'play_data.dart';
import 'play_table.dart';

abstract class MoveAction {
  const MoveAction();

  MoveActionResult action(MoveActionData data);

  static MoveActionResult run(
    List<MoveAction>? actions,
    MoveActionData data,
  ) {
    if (actions == null) {
      return MoveActionNoChange(table: data.table);
    }

    Action? action;
    List<MoveEvent> events = [];
    bool hasChange = false;
    PlayTable table = data.table;

    for (final item in actions) {
      final result = item.action(data.withTable(table));
      switch (result) {
        case (MoveActionHandled()):
          hasChange = true;
          if (result.action != null) {
            if (action != null) {
              throw StateError('Move is already assigned');
            }
            action = result.action;
          }
          table = result.table;
          if (result.events.isNotEmpty) {
            events.addAll(result.events);
          }
        case MoveActionNoChange():
      }
    }

    if (hasChange) {
      return MoveActionHandled(table: table, action: action, events: events);
    } else {
      return MoveActionNoChange(table: table);
    }
  }

  static MoveActionResult chain(
    MoveActionResult pastResult,
    List<MoveAction>? actions,
    MoveActionData data,
  ) {
    if (pastResult is! MoveActionHandled) {
      return pastResult;
    }
    PlayTable table = pastResult.table;
    Action? action = pastResult.action;
    List<MoveEvent> events = pastResult.events;

    final currentResult = MoveAction.run(actions, data.withTable(table));

    if (currentResult is MoveActionHandled) {
      table = currentResult.table;

      if (currentResult.action != null) {
        if (action != null) {
          throw StateError('Action is already assigned');
        }
        action = currentResult.action;
      }
      if (currentResult.events.isNotEmpty) {
        events.addAll(currentResult.events);
      }
    }
    return MoveActionHandled(
      table: table,
      action: action,
      events: events,
    );
  }
}

class MoveActionData {
  MoveActionData({
    required this.pile,
    required this.table,
    this.metadata,
    this.moveState,
  });

  final Pile pile;
  final PlayTable table;
  final GameMetadata? metadata;
  final MoveState? moveState;

  MoveActionData withTable(PlayTable newTable) {
    return MoveActionData(
      pile: pile,
      table: newTable,
      metadata: metadata,
      moveState: moveState,
    );
  }

  MoveActionData withPile(Pile newPile) {
    return MoveActionData(
      pile: newPile,
      table: table,
      metadata: metadata,
      moveState: moveState,
    );
  }
}

sealed class MoveActionResult {
  final PlayTable table;

  const MoveActionResult({required this.table});
}

class MoveActionHandled extends MoveActionResult {
  const MoveActionHandled({
    required super.table,
    this.action,
    this.events = const [],
  });

  final Action? action;
  final List<MoveEvent> events;
}

class MoveActionNoChange extends MoveActionResult {
  const MoveActionNoChange({required super.table});
}

class If extends MoveAction {
  const If({
    required this.condition,
    this.ifTrue,
    this.ifFalse,
  });

  final List<MoveCheck> condition;
  final List<MoveAction>? ifTrue;
  final List<MoveAction>? ifFalse;

  @override
  MoveActionResult action(MoveActionData data) {
    final cond = MoveCheck.checkAll(
      condition,
      MoveCheckData(
        pile: data.pile,
        table: data.table,
        moveState: data.moveState,
      ),
    );

    if (cond is MoveCheckOK && ifTrue != null) {
      return MoveAction.run(ifTrue, data);
    } else if (cond is MoveCheckFail && ifFalse != null) {
      return MoveAction.run(ifFalse, data);
    } else {
      return MoveActionNoChange(table: data.table);
    }
  }
}

// -------------------------------------------------------

class SetupNewDeck extends MoveAction {
  const SetupNewDeck({this.count = 1, this.onlySuit});

  final int count;

  final List<Suit>? onlySuit;

  @override
  MoveActionResult action(MoveActionData data) {
    final existingCards = data.table.get(data.pile);

    final newCards = const PlayCardGenerator().generateShuffledDeck(
      numberOfDecks: count,
      CustomPRNG.create(data.metadata!.randomSeed),
      criteria:
          onlySuit != null ? (card) => onlySuit!.contains(card.suit) : null,
    );

    return MoveActionHandled(
      table: data.table.modify(data.pile, [...existingCards, ...newCards]),
    );
  }
}

class FlipAllCardsFaceUp extends MoveAction {
  const FlipAllCardsFaceUp();

  @override
  MoveActionResult action(MoveActionData data) {
    return MoveActionHandled(
      table: data.table.modify(data.pile, data.table.get(data.pile).allFaceUp),
    );
  }
}

class FlipAllCardsFaceDown extends MoveAction {
  const FlipAllCardsFaceDown();

  @override
  MoveActionResult action(MoveActionData data) {
    return MoveActionHandled(
      table:
          data.table.modify(data.pile, data.table.get(data.pile).allFaceDown),
    );
  }
}
//
// class PickCardsFrom extends PileAction {
//   const PickCardsFrom(this.fromPile, {required this.count});
//
//   final Pile fromPile;
//
//   final int count;
//
//   @override
//   PileActionResult action(PileActionData data) {
//     final cardsFromPile = data.table.get(fromPile);
//     final (remainingCards, cardsToPick) = cardsFromPile.splitLast(count);
//
//     return PileActionHandled(
//       table: data.table.modifyMultiple({
//         fromPile: remainingCards,
//         data.pile: cardsToPick,
//       }),
//     );
//   }
// }

class MoveNormally extends MoveAction {
  const MoveNormally({required this.to, required this.cards});
  final Pile to;
  final List<PlayCard> cards;

  @override
  MoveActionResult action(MoveActionData data) {
    final cardsInHand = cards;
    final cardsOnTable = data.table.get(data.pile);

    // Check and remove cards from source pile to hand
    final (remainingCards, cardsToPickUp) =
        cardsOnTable.splitLast(cardsInHand.length);

    // Check whether card picked is similar to what is on hand
    // if (!const ListEquality().equals(cardsToPickUp, cardsInHand)) {
    //   throw StateError("Cards picked up and in hand is not the same");
    // }

    // Move all cards on hand to target pile
    return MoveActionHandled(
      table: data.table.modifyMultiple({
        data.pile: remainingCards,
        to: [...data.table.get(to), ...cardsToPickUp]
      }),
      action: Move(cardsToPickUp, data.pile, to),
      events: [MoveMade(from: data.pile, to: to)],
    );
  }
}

class DrawFromTop extends MoveAction {
  const DrawFromTop({
    required this.to,
    required this.count,
  });
  final Pile to;
  final int count;

  @override
  MoveActionResult action(MoveActionData data) {
    final cardsOnTable = data.table.get(data.pile);

    // Check and remove cards from source pile to hand
    final (remainingCards, cardsToPickUp) = cardsOnTable.splitLast(count);

    // Check whether card picked is similar to what is on hand
    // if (!const ListEquality().equals(cardsToPickUp, cardsInHand)) {
    //   throw StateError("Cards picked up and in hand is not the same");
    // }

    // Move all cards on hand to target pile
    return MoveActionHandled(
      table: data.table.modifyMultiple({
        data.pile: remainingCards,
        to: [...data.table.get(to), ...cardsToPickUp.allFaceUp]
      }),
      action: Move(cardsToPickUp, data.pile, to),
    );
  }
}

class RecyclePile extends MoveAction {
  const RecyclePile({required this.takeFrom});
  final Pile takeFrom;

  @override
  MoveActionResult action(MoveActionData data) {
    final cardsToRecycle = data.table.get(takeFrom).reversed.toList();
    return MoveActionHandled(
      table: data.table.modifyMultiple({
        takeFrom: [],
        data.pile: [
          ...data.table.get(data.pile),
          ...cardsToRecycle.allFaceDown,
        ],
      }),
      action: Deal(cardsToRecycle, data.pile),
      events: [RecycleMade(data.pile)],
    );
  }
}

class FlipTopCardFaceUp extends MoveAction {
  const FlipTopCardFaceUp({this.count = 1});

  final int count;

  @override
  MoveActionResult action(MoveActionData data) {
    final cardsOnPile = data.table.get(data.pile);

    if (cardsOnPile.isEmpty || cardsOnPile.last.isFacingUp) {
      return MoveActionNoChange(table: data.table);
    }

    final (remainingCards, cardsToFlip) = cardsOnPile.splitLast(count);

    return MoveActionHandled(
      table: data.table.modify(
        data.pile,
        [...remainingCards, ...cardsToFlip.allFaceUp],
      ),
    );
  }
}

class DistributeTo<T extends Pile> extends MoveAction {
  const DistributeTo({required this.distribution, this.afterMove});

  final List<int> distribution;

  final List<MoveAction>? afterMove;

  @override
  MoveActionResult action(MoveActionData data) {
    final targetPiles = data.table.allPilesOfType<T>().toList();

    if (targetPiles.length != distribution.length) {
      throw ArgumentError(
          'Distribution length must be equal to amount of piles of type $T');
    }
    final cardsOnOriginPile = data.table.get(data.pile);
    final totalCardsToTake = distribution.sum;

    if (totalCardsToTake > cardsOnOriginPile.length) {
      throw ArgumentError(
          'Insufficient cards to take. Want: $totalCardsToTake, have: ${cardsOnOriginPile.length}');
    }

    final (remainingCards, cardsToTake) =
        cardsOnOriginPile.splitLast(totalCardsToTake);

    // Reverse list for faster access
    final cardsToDistribute = cardsToTake.reversed.toList();

    final maxDistributionHeight = distribution.max;
    final List<List<PlayCard>> cardSlots =
        List.generate(targetPiles.length, (_) => []);

    for (int d = 0; d < maxDistributionHeight; d++) {
      for (int i = 0; i < targetPiles.length; i++) {
        if (d < distribution[i]) {
          cardSlots[i].add(cardsToDistribute.removeLast());
        }
      }
    }

    assert(cardsToDistribute.isEmpty,
        'Leftover cards should be empty after distribution');

    final result = MoveActionHandled(
      table: data.table.modifyMultiple({
        data.pile: remainingCards,
        // TODO: Check for index ordering
        for (final (i, p) in targetPiles.indexed)
          p: [...data.table.get(p), ...cardSlots[i].allFaceUp]
      }),
      // TODO: Change this
      action: Deal(cardsToTake, data.pile),
    );

    if (afterMove != null) {
      return targetPiles.fold(
        result,
        (result, pile) =>
            MoveAction.chain(result, afterMove, data.withPile(pile)),
      );
    } else {
      return result;
    }
  }
}

class EmitEvent extends MoveAction {
  const EmitEvent(this.event);

  final MoveEvent event;

  @override
  MoveActionResult action(MoveActionData data) {
    return MoveActionHandled(
      table: data.table,
      events: [event],
    );
  }
}

class ArrangePenguinFoundations extends MoveAction {
  const ArrangePenguinFoundations({
    required this.firstCardGoesTo,
    required this.relatedCardsGoTo,
  });

  final Pile firstCardGoesTo;

  final List<Pile> relatedCardsGoTo;

  @override
  MoveActionResult action(MoveActionData data) {
    final cardsInStock = data.table.get(data.pile);
    final firstCard = cardsInStock.first;

    final (remainingCards, relatedCards) =
        cardsInStock.splitWhere((card) => card.rank == firstCard.rank);

    return MoveActionHandled(
      table: data.table.modifyMultiple({
        data.pile: remainingCards,
        firstCardGoesTo: [relatedCards.first.faceUp],
        for (final (index, pile) in relatedCardsGoTo.indexed)
          pile: [relatedCards[index + 1].faceUp],
      }),
    );
  }
}
