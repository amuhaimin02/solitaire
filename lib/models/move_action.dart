import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../services/all.dart';
import '../services/play_card_generator.dart';
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

  MoveActionResult run(MoveActionArgs args);

  static MoveActionResult runAll(
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
      final result = item.run(args.copyWith(table: table));
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

    final currentResult =
        MoveAction.runAll(actions, args.copyWith(table: table));

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
  MoveActionResult run(MoveActionArgs args) {
    final cond = MoveCheck.checkAll(
      condition,
      MoveCheckArgs(
        pile: args.pile,
        table: args.table,
        moveState: args.moveState,
      ),
    );

    if (cond is MoveCheckOK && ifTrue != null) {
      return MoveAction.runAll(ifTrue, args);
    } else if (cond is MoveCheckFail && ifFalse != null) {
      return MoveAction.runAll(ifFalse, args);
    } else {
      return MoveActionNoChange(table: args.table);
    }
  }
}

// -------------------------------------------------------

class SetupNewDeck extends MoveAction {
  const SetupNewDeck({this.count = 1, this.onlySuit, this.criteria});

  final int count;

  final List<Suit>? onlySuit;

  final bool Function(PlayCard card)? criteria;

  @override
  MoveActionResult run(MoveActionArgs args) {
    final newCards = services<PlayCardGenerator>().generateShuffledDeck(
      numberOfDecks: count,
      CustomPRNG.create(args.metadata!.randomSeed),
      criteria: (card) {
        if (onlySuit != null) {
          if (onlySuit!.contains(card.suit) == false) {
            return false;
          }
        }
        if (criteria != null) {
          if (criteria!.call(card) == false) {
            return false;
          }
        }
        return true;
      },
    );

    return MoveActionHandled(
      table: args.table.add(args.pile, newCards.allFaceDown),
    );
  }
}

class FlipAllCardsFaceUp extends MoveAction {
  const FlipAllCardsFaceUp();

  @override
  MoveActionResult run(MoveActionArgs args) {
    return MoveActionHandled(
      table: args.table.modify(args.pile, (c) => c.faceUp),
    );
  }
}

class FlipAllCardsFaceDown extends MoveAction {
  const FlipAllCardsFaceDown();

  @override
  MoveActionResult run(MoveActionArgs args) {
    return MoveActionHandled(
      table: args.table.modify(args.pile, (c) => c.faceDown),
    );
  }
}

class MoveNormally extends MoveAction {
  const MoveNormally({required this.to, required this.count});
  final Pile to;
  final int count;

  @override
  MoveActionResult run(MoveActionArgs args) {
    final cardsOnTable = args.table.get(args.pile);

    // Check and remove cards from source pile to hand
    final (remainingCards, cardsToPickUp) = cardsOnTable.splitLast(count);

    // Check whether card picked is similar to what is on hand
    // if (!const ListEquality().equals(cardsToPickUp, cardsInHand)) {
    //   throw StateError("Cards picked up and in hand is not the same");
    // }

    // Move all cards on hand to target pile
    return MoveActionHandled(
      table:
          args.table.change(args.pile, remainingCards).add(to, cardsToPickUp),
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
  MoveActionResult run(MoveActionArgs args) {
    final cardsOnTable = args.table.get(args.pile);

    // Check and remove cards from source pile to hand
    final (remainingCards, cardsToPickUp) = cardsOnTable.splitLast(count);

    // Move all cards on hand to target pile
    return MoveActionHandled(
      table: args.table
          .change(args.pile, remainingCards)
          .add(to, cardsToPickUp.allFaceUp),
      action: Draw(cardsToPickUp, args.pile, to),
    );
  }
}

class RecyclePile extends MoveAction {
  const RecyclePile({required this.takeFrom, this.faceUp = false});
  final Pile takeFrom;
  final bool faceUp;

  @override
  MoveActionResult run(MoveActionArgs args) {
    final cardsToRecycle = args.table.get(takeFrom).reversed;
    return MoveActionHandled(
      table: args.table.clear(takeFrom).add(args.pile,
          faceUp ? cardsToRecycle.allFaceUp : cardsToRecycle.allFaceDown),
      action: Deal(cardsToRecycle, args.pile),
      events: [RecycleMade(args.pile)],
    );
  }
}

class FlipTopCardFaceUp extends MoveAction {
  const FlipTopCardFaceUp({this.count = 1});

  final int count;

  @override
  MoveActionResult run(MoveActionArgs args) {
    final cardsOnPile = args.table.get(args.pile);

    if (cardsOnPile.isEmpty || cardsOnPile.last.isFacingUp) {
      return MoveActionNoChange(table: args.table);
    }

    final (remainingCards, cardsToFlip) = cardsOnPile.splitLast(count);

    return MoveActionHandled(
      table: args.table.change(
        args.pile,
        remainingCards.addAll(cardsToFlip.allFaceUp),
      ),
    );
  }
}

class DistributeTo<T extends Pile> extends MoveAction {
  const DistributeTo({
    required this.distribution,
    this.countAsMove = false,
    this.allowPartial = false,
  });

  final List<int> distribution;

  final bool countAsMove;

  final bool allowPartial;

  @override
  MoveActionResult run(MoveActionArgs args) {
    final targetPiles = args.table.allPilesOfType<T>().toList();

    if (targetPiles.length != distribution.length) {
      throw ArgumentError(
          'Distribution length must be equal to amount of piles of type $T');
    }
    final cardsOnOriginPile = args.table.get(args.pile);
    final totalCardsToTake = distribution.sum;

    if (!allowPartial && totalCardsToTake > cardsOnOriginPile.length) {
      throw ArgumentError(
          'Insufficient cards to take. Want: $totalCardsToTake, have: ${cardsOnOriginPile.length}');
    }

    final (remainingCards, cardsToTake) =
        cardsOnOriginPile.splitLast(totalCardsToTake);

    // Reverse list for faster access
    final cardsToDistribute = cardsToTake.reversed.toList();

    final maxDistributionHeight = distribution.max;
    final List<PlayCardList> cardSlots =
        List.generate(targetPiles.length, (_) => const PlayCardList.empty());

    // TODO: Optimize
    for (int d = 0; d < maxDistributionHeight; d++) {
      for (int i = 0; i < targetPiles.length; i++) {
        if (d < distribution[i]) {
          if (cardsToDistribute.isNotEmpty) {
            cardSlots[i] = cardSlots[i].add(cardsToDistribute.removeLast());
          }
        }
      }
    }

    assert(cardsToDistribute.isEmpty,
        'Leftover cards should be empty after distribution');

    PlayTable table = args.table.change(args.pile, remainingCards);
    for (final (i, p) in targetPiles.indexed) {
      table = table.add(p, cardSlots[i].allFaceUp);
    }

    final result = MoveActionHandled(
      table: table,
      // TODO: Change this
      action: countAsMove ? Deal(cardsToTake, args.pile) : null,
    );

    return result;
  }
}

class EmitEvent extends MoveAction {
  const EmitEvent(this.event);

  final MoveEvent event;

  @override
  MoveActionResult run(MoveActionArgs args) {
    return MoveActionHandled(
      table: args.table,
      events: [event],
    );
  }
}

class FlipExposedCardsFaceUp extends MoveAction {
  const FlipExposedCardsFaceUp();

  @override
  MoveActionResult run(MoveActionArgs args) {
    final grids = args.table.allPilesOfType<Grid>();

    PlayTable table = args.table;

    for (final grid in grids) {
      if (const PileIsExposed()
          .check(MoveCheckArgs(pile: grid, table: table))) {
        table = table.modify(grid, (c) => c.faceUp);
      }
    }

    return MoveActionHandled(table: table);
  }
}

class FindCardsAndMove extends MoveAction {
  const FindCardsAndMove({
    required this.where,
    this.firstCardOnly = false,
    required this.moveTo,
  });

  final bool Function(PlayCard card, PlayCardList cardsOnPile) where;
  final bool firstCardOnly;
  final Pile moveTo;

  @override
  MoveActionResult run(MoveActionArgs args) {
    final cardsOnPile = args.table.get(args.pile);
    final (remainingCards, foundCards) = cardsOnPile.splitWhere(
      (c) => where(c, cardsOnPile),
      firstCardOnly: firstCardOnly,
    );

    return MoveActionHandled(
      table:
          args.table.change(args.pile, remainingCards).add(moveTo, foundCards),
    );
  }
}

class ForAllPilesOfType<T extends Pile> extends MoveAction {
  const ForAllPilesOfType(this.actions);

  final List<MoveAction>? actions;

  @override
  MoveActionResult run(MoveActionArgs args) {
    MoveActionResult? result;

    for (final pile in args.table.allPilesOfType<T>()) {
      if (result == null) {
        result = MoveAction.runAll(actions, args.copyWith(pile: pile));
      } else {
        result = MoveAction.chain(result, actions, args.copyWith(pile: pile));
      }
    }

    return result!;
  }
}
