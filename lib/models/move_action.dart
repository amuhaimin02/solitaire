import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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

part 'move_action.freezed.dart';

abstract class MoveAction {
  const MoveAction();

  MoveActionResult action(MoveActionArgs args);

  static MoveActionResult run(
    List<MoveAction>? actions,
    MoveActionArgs args,
  ) {
    if (actions == null) {
      return MoveActionNoChange(table: args.table);
    }

    Action? action;
    List<MoveEvent> events = [];
    bool hasChange = false;
    PlayTable table = args.table;

    for (final item in actions) {
      final result = item.action(args.copyWith(table: table));
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
    MoveActionArgs args,
  ) {
    if (pastResult is! MoveActionHandled) {
      return pastResult;
    }
    PlayTable table = pastResult.table;
    Action? action = pastResult.action;
    List<MoveEvent> events = pastResult.events;

    final currentResult = MoveAction.run(actions, args.copyWith(table: table));

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

@freezed
class MoveActionArgs with _$MoveActionArgs {
  const factory MoveActionArgs({
    required Pile pile,
    required PlayTable table,
    GameMetadata? metadata,
    MoveState? moveState,
    Action? lastAction,
  }) = _MoveActionArgs;
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
  MoveActionResult action(MoveActionArgs args) {
    final cond = MoveCheck.checkAll(
      condition,
      MoveCheckArgs(
        pile: args.pile,
        table: args.table,
        moveState: args.moveState,
      ),
    );

    if (cond is MoveCheckOK && ifTrue != null) {
      return MoveAction.run(ifTrue, args);
    } else if (cond is MoveCheckFail && ifFalse != null) {
      return MoveAction.run(ifFalse, args);
    } else {
      return MoveActionNoChange(table: args.table);
    }
  }
}

// -------------------------------------------------------

class SetupNewDeck extends MoveAction {
  const SetupNewDeck({this.count = 1, this.onlySuit});

  final int count;

  final List<Suit>? onlySuit;

  @override
  MoveActionResult action(MoveActionArgs args) {
    final existingCards = args.table.get(args.pile);

    final newCards = const PlayCardGenerator().generateShuffledDeck(
      numberOfDecks: count,
      CustomPRNG.create(args.metadata!.randomSeed),
      criteria:
          onlySuit != null ? (card) => onlySuit!.contains(card.suit) : null,
    );

    return MoveActionHandled(
      table: args.table.modify(args.pile, [...existingCards, ...newCards]),
    );
  }
}

class FlipAllCardsFaceUp extends MoveAction {
  const FlipAllCardsFaceUp();

  @override
  MoveActionResult action(MoveActionArgs args) {
    return MoveActionHandled(
      table: args.table.modify(args.pile, args.table.get(args.pile).allFaceUp),
    );
  }
}

class FlipAllCardsFaceDown extends MoveAction {
  const FlipAllCardsFaceDown();

  @override
  MoveActionResult action(MoveActionArgs args) {
    return MoveActionHandled(
      table:
          args.table.modify(args.pile, args.table.get(args.pile).allFaceDown),
    );
  }
}

class MoveNormally extends MoveAction {
  const MoveNormally({required this.to, required this.cards});
  final Pile to;
  final List<PlayCard> cards;

  @override
  MoveActionResult action(MoveActionArgs args) {
    final cardsInHand = cards;
    final cardsOnTable = args.table.get(args.pile);

    // Check and remove cards from source pile to hand
    final (remainingCards, cardsToPickUp) =
        cardsOnTable.splitLast(cardsInHand.length);

    // Check whether card picked is similar to what is on hand
    // if (!const ListEquality().equals(cardsToPickUp, cardsInHand)) {
    //   throw StateError("Cards picked up and in hand is not the same");
    // }

    // Move all cards on hand to target pile
    return MoveActionHandled(
      table: args.table.modifyMultiple({
        args.pile: remainingCards,
        to: [...args.table.get(to), ...cardsToPickUp]
      }),
      action: Move(cardsToPickUp, args.pile, to),
      events: [MoveMade(from: args.pile, to: to)],
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
  MoveActionResult action(MoveActionArgs args) {
    final cardsOnTable = args.table.get(args.pile);

    // Check and remove cards from source pile to hand
    final (remainingCards, cardsToPickUp) = cardsOnTable.splitLast(count);

    // Check whether card picked is similar to what is on hand
    // if (!const ListEquality().equals(cardsToPickUp, cardsInHand)) {
    //   throw StateError("Cards picked up and in hand is not the same");
    // }

    // Move all cards on hand to target pile
    return MoveActionHandled(
      table: args.table.modifyMultiple({
        args.pile: remainingCards,
        to: [...args.table.get(to), ...cardsToPickUp.allFaceUp]
      }),
      action: Draw(cardsToPickUp, args.pile, to),
    );
  }
}

class RecyclePile extends MoveAction {
  const RecyclePile({required this.takeFrom, this.faceUp = false});
  final Pile takeFrom;
  final bool faceUp;

  @override
  MoveActionResult action(MoveActionArgs args) {
    final cardsToRecycle = args.table.get(takeFrom).reversed.toList();
    return MoveActionHandled(
      table: args.table.modifyMultiple({
        takeFrom: [],
        args.pile: [
          ...args.table.get(args.pile),
          if (faceUp)
            ...cardsToRecycle.allFaceUp
          else
            ...cardsToRecycle.allFaceDown
        ],
      }),
      action: Deal(cardsToRecycle, args.pile),
      events: [RecycleMade(args.pile)],
    );
  }
}

class FlipTopCardFaceUp extends MoveAction {
  const FlipTopCardFaceUp({this.count = 1});

  final int count;

  @override
  MoveActionResult action(MoveActionArgs args) {
    final cardsOnPile = args.table.get(args.pile);

    if (cardsOnPile.isEmpty || cardsOnPile.last.isFacingUp) {
      return MoveActionNoChange(table: args.table);
    }

    final (remainingCards, cardsToFlip) = cardsOnPile.splitLast(count);

    return MoveActionHandled(
      table: args.table.modify(
        args.pile,
        [...remainingCards, ...cardsToFlip.allFaceUp],
      ),
    );
  }
}

class DistributeTo<T extends Pile> extends MoveAction {
  const DistributeTo({
    required this.distribution,
    this.afterMove,
    this.countAsMove = false,
  });

  final List<int> distribution;

  final List<MoveAction>? afterMove;

  final bool countAsMove;

  @override
  MoveActionResult action(MoveActionArgs args) {
    final targetPiles = args.table.allPilesOfType<T>().toList();

    if (targetPiles.length != distribution.length) {
      throw ArgumentError(
          'Distribution length must be equal to amount of piles of type $T');
    }
    final cardsOnOriginPile = args.table.get(args.pile);
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
      table: args.table.modifyMultiple({
        args.pile: remainingCards,
        // TODO: Check for index ordering
        for (final (i, p) in targetPiles.indexed)
          p: [...args.table.get(p), ...cardSlots[i].allFaceUp]
      }),
      // TODO: Change this
      action: countAsMove ? Deal(cardsToTake, args.pile) : null,
    );

    if (afterMove != null) {
      return targetPiles.fold(
        result,
        (result, pile) =>
            MoveAction.chain(result, afterMove, args.copyWith(pile: pile)),
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
  MoveActionResult action(MoveActionArgs args) {
    return MoveActionHandled(
      table: args.table,
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
  MoveActionResult action(MoveActionArgs args) {
    final cardsInStock = args.table.get(args.pile);
    final firstCard = cardsInStock.first;

    final (remainingCards, relatedCards) =
        cardsInStock.splitWhere((card) => card.rank == firstCard.rank);

    return MoveActionHandled(
      table: args.table.modifyMultiple({
        args.pile: remainingCards,
        firstCardGoesTo: [relatedCards.first.faceUp],
        for (final (index, pile) in relatedCardsGoTo.indexed)
          pile: [relatedCards[index + 1].faceUp],
      }),
    );
  }
}

class FlipExposedCardsFaceUp extends MoveAction {
  const FlipExposedCardsFaceUp();

  @override
  MoveActionResult action(MoveActionArgs args) {
    final grids = args.table.allPilesOfType<Grid>();

    PlayTable updatedTable = args.table;

    for (final grid in grids) {
      if (const PileIsExposed()
          .check(MoveCheckArgs(pile: grid, table: updatedTable))) {
        final cardsInGrid = args.table.get(grid);
        updatedTable = updatedTable.modify(grid, cardsInGrid.allFaceUp);
      }
    }

    return MoveActionHandled(table: updatedTable);
  }
}
