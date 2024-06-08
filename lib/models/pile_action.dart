import 'package:collection/collection.dart';

import '../services/card_shuffler.dart';
import '../utils/prng.dart';
import 'action.dart';
import 'card.dart';
import 'card_list.dart';
import 'move_event.dart';
import 'move_record.dart';
import 'pile.dart';
import 'pile_check.dart';
import 'play_data.dart';
import 'play_table.dart';

abstract class PileAction {
  const PileAction();

  PileActionResult action(PileActionData data);

  static PileActionResult run(
    List<PileAction>? actions,
    PileActionData data,
  ) {
    if (actions == null) {
      return PileActionNoChange(table: data.table);
    }

    Action? action;
    List<MoveEvent> events = [];
    bool hasChange = false;
    PlayTable table = data.table;

    for (final item in actions) {
      final result = item.action(data.withTable(table));
      switch (result) {
        case (PileActionHandled()):
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
        case PileActionNoChange():
      }
    }

    if (hasChange) {
      return PileActionHandled(table: table, action: action, events: events);
    } else {
      return PileActionNoChange(table: table);
    }
  }

  static PileActionResult chain(PileActionResult pastResult,
      List<PileAction>? actions, PileActionData data) {
    if (pastResult is! PileActionHandled) {
      return pastResult;
    }
    PlayTable table = pastResult.table;
    Action? action = pastResult.action;
    List<MoveEvent> events = pastResult.events;

    final currentResult = PileAction.run(actions, data.withTable(table));

    if (currentResult is PileActionHandled) {
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
    return PileActionHandled(
      table: table,
      action: action,
      events: events,
    );
  }
}

class PileActionData {
  PileActionData({
    required this.pile,
    required this.table,
    this.metadata,
    this.moveState,
  });

  final Pile pile;
  final PlayTable table;
  final GameMetadata? metadata;
  final MoveState? moveState;

  PileActionData withTable(PlayTable newTable) {
    return PileActionData(
      pile: pile,
      table: newTable,
      metadata: metadata,
      moveState: moveState,
    );
  }
}

sealed class PileActionResult {
  final PlayTable table;

  const PileActionResult({required this.table});
}

class PileActionHandled extends PileActionResult {
  const PileActionHandled({
    required super.table,
    this.action,
    this.events = const [],
  });

  final Action? action;
  final List<MoveEvent> events;
}

class PileActionNoChange extends PileActionResult {
  const PileActionNoChange({required super.table});
}

class If extends PileAction {
  const If({
    required this.condition,
    this.ifTrue,
    this.ifFalse,
  });

  final List<PileCheck> condition;
  final List<PileAction>? ifTrue;
  final List<PileAction>? ifFalse;

  @override
  PileActionResult action(PileActionData data) {
    // TODO: Where to obtain the remaining param?
    final cond = PileCheck.checkAll(
      condition,
      PileCheckData(
        pile: data.pile,
        cards: [],
        table: data.table,
        moveState: data.moveState,
      ),
    );

    if (cond is PileCheckOK && ifTrue != null) {
      return PileAction.run(ifTrue, data);
    } else if (cond is PileCheckFail && ifFalse != null) {
      return PileAction.run(ifFalse, data);
    } else {
      return PileActionNoChange(table: data.table);
    }
  }
}

// -------------------------------------------------------

class SetupNewDeck extends PileAction {
  const SetupNewDeck({this.count = 1, this.onlySuit});

  final int count;

  final List<Suit>? onlySuit;

  @override
  PileActionResult action(PileActionData data) {
    final existingCards = data.table.get(data.pile);

    final newCards = const PlayCardGenerator().generateShuffledDeck(
      numberOfDecks: count,
      CustomPRNG.create(data.metadata!.randomSeed),
      criteria:
          onlySuit != null ? (card) => onlySuit!.contains(card.suit) : null,
    );

    return PileActionHandled(
      table: data.table.modify(data.pile, [...existingCards, ...newCards]),
    );
  }
}

class FlipAllCardsFaceUp extends PileAction {
  const FlipAllCardsFaceUp();

  @override
  PileActionResult action(PileActionData data) {
    return PileActionHandled(
      table: data.table.modify(data.pile, data.table.get(data.pile).allFaceUp),
    );
  }
}

class FlipAllCardsFaceDown extends PileAction {
  const FlipAllCardsFaceDown();

  @override
  PileActionResult action(PileActionData data) {
    return PileActionHandled(
      table:
          data.table.modify(data.pile, data.table.get(data.pile).allFaceDown),
    );
  }
}

class PickCardsFrom extends PileAction {
  const PickCardsFrom(this.fromPile, {required this.count});

  final Pile fromPile;

  final int count;

  @override
  PileActionResult action(PileActionData data) {
    final cardsFromPile = data.table.get(fromPile);
    final (remainingCards, cardsToPick) = cardsFromPile.splitLast(count);

    return PileActionHandled(
      table: data.table.modifyMultiple({
        fromPile: remainingCards,
        data.pile: cardsToPick,
      }),
    );
  }
}

class MoveNormally extends PileAction {
  const MoveNormally({required this.to, required this.cards});
  final Pile to;
  final List<PlayCard> cards;

  @override
  PileActionResult action(PileActionData data) {
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
    return PileActionHandled(
      table: data.table.modifyMultiple({
        data.pile: remainingCards,
        to: [...data.table.get(to), ...cardsToPickUp]
      }),
      action: Move(cardsToPickUp, data.pile, to),
      events: [MoveMade(from: data.pile, to: to)],
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
  PileActionResult action(PileActionData data) {
    final cardsOnTable = data.table.get(data.pile);

    // Check and remove cards from source pile to hand
    final (remainingCards, cardsToPickUp) = cardsOnTable.splitLast(count);

    // Check whether card picked is similar to what is on hand
    // if (!const ListEquality().equals(cardsToPickUp, cardsInHand)) {
    //   throw StateError("Cards picked up and in hand is not the same");
    // }

    // Move all cards on hand to target pile
    return PileActionHandled(
      table: data.table.modifyMultiple({
        data.pile: remainingCards,
        to: [...data.table.get(to), ...cardsToPickUp.allFaceUp]
      }),
      action: Move(cardsToPickUp, data.pile, to),
    );
  }
}

class RecyclePile extends PileAction {
  const RecyclePile({required this.takeFrom});
  final Pile takeFrom;

  @override
  PileActionResult action(PileActionData data) {
    final cardsToRecycle = data.table.get(takeFrom).reversed.toList();
    return PileActionHandled(
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

class FlipTopCardFaceUp extends PileAction {
  const FlipTopCardFaceUp();

  @override
  PileActionResult action(PileActionData data) {
    final cardsOnPile = data.table.get(data.pile);

    if (cardsOnPile.isEmpty || cardsOnPile.last.isFacingUp) {
      return PileActionNoChange(table: data.table);
    }

    return PileActionHandled(
      table: data.table.modify(
        data.pile,
        [
          ...cardsOnPile.slice(0, cardsOnPile.length - 1),
          cardsOnPile.last.faceUp()
        ],
      ),
    );
  }
}

class DrawToAllPilesOfType<T extends Pile> extends PileAction {
  const DrawToAllPilesOfType({required this.count});

  final int count;

  @override
  PileActionResult action(PileActionData data) {
    final allPilesOfType = data.table.allPilesOfType<T>().toList();
    final (remainingCards, cardsToDistribute) =
        data.table.get(data.pile).splitLast(allPilesOfType.length);

    // TODO: Support count more than 1
    return PileActionHandled(
      table: data.table.modifyMultiple({
        data.pile: remainingCards,
        for (final (i, p) in allPilesOfType.indexed)
          p: [...data.table.get(p), cardsToDistribute[i].faceUp()]
      }),
      // TODO: Change this
      action: Deal(cardsToDistribute, data.pile),
    );
  }
}

class EmitEvent extends PileAction {
  const EmitEvent(this.event);

  final MoveEvent event;

  @override
  PileActionResult action(PileActionData data) {
    return PileActionHandled(
      table: data.table,
      events: [event],
    );
  }
}
