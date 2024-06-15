import 'dart:math';

import 'package:change_case/change_case.dart';
import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../utils/types.dart';
import 'card.dart';
import 'card_list.dart';
import 'move_record.dart';
import 'pile.dart';
import 'play_table.dart';
import 'rank_order.dart';

part 'move_check.freezed.dart';

abstract class MoveCheck {
  const MoveCheck();

  bool check(MoveCheckArgs args);

  String get errorMessage;

  static MoveCheckResult checkAll(
    List<MoveCheck>? checks,
    MoveCheckArgs args,
  ) {
    if (checks == null) {
      return const MoveCheckFail(reason: null);
    }
    for (final item in checks) {
      if (!item.check(args)) {
        return MoveCheckFail(reason: item);
      }
    }
    return const MoveCheckOK();
  }

  MoveCheck operator |(MoveCheck other) {
    return _MoveCheckOr(this, other);
  }
}

class _MoveCheckOr extends MoveCheck {
  const _MoveCheckOr(this.check1, this.check2);

  final MoveCheck check1;
  final MoveCheck check2;

  @override
  String get errorMessage =>
      '${check1.errorMessage}, or ${check2.errorMessage}';

  @override
  bool check(MoveCheckArgs args) {
    return check1.check(args) || check2.check(args);
  }
}

@freezed
class MoveCheckArgs with _$MoveCheckArgs {
  const factory MoveCheckArgs({
    required Pile pile,
    @Default([]) List<PlayCard> cards,
    required PlayTable table,
    MoveState? moveState,
    Pile? originPile,
  }) = _MoveCheckArgs;
}

sealed class MoveCheckResult {
  const MoveCheckResult();
}

class MoveCheckOK extends MoveCheckResult {
  const MoveCheckOK();
}

class MoveCheckFail extends MoveCheckResult {
  const MoveCheckFail({required this.reason});

  final MoveCheck? reason;
}

class Select extends MoveCheck {
  const Select({
    required this.condition,
    this.ifTrue,
    this.ifFalse,
  });

  final List<MoveCheck> condition;
  final List<MoveCheck>? ifTrue;
  final List<MoveCheck>? ifFalse;

  @override
  // TODO: Implement
  String get errorMessage => '';

  @override
  bool check(MoveCheckArgs args) {
    final cond = MoveCheck.checkAll(condition, args);

    if (cond is MoveCheckOK && ifTrue != null) {
      return MoveCheck.checkAll(ifTrue, args) is MoveCheckOK;
    } else if (cond is MoveCheckFail && ifFalse != null) {
      return MoveCheck.checkAll(ifFalse, args) is MoveCheckOK;
    } else {
      return false;
    }
  }
}

extension MoveCheckListExtension on List<MoveCheck> {
  T? findRule<T extends MoveCheck>() {
    return firstWhereOrNull((e) => e is T) as T?;
  }
}

class CardsAreFacingUp extends MoveCheck {
  const CardsAreFacingUp();

  @override
  String get errorMessage => 'Cards must all be facing up';

  @override
  bool check(MoveCheckArgs args) {
    return args.cards.isAllFacingUp;
  }
}

class CardIsSingle extends MoveCheck {
  const CardIsSingle();

  @override
  String get errorMessage => 'Only a single card is allowed';

  @override
  bool check(MoveCheckArgs args) {
    return args.cards.isSingle;
  }
}

class CardIsOnTop extends MoveCheck {
  const CardIsOnTop();

  @override
  String get errorMessage => 'Card is not on top';

  @override
  bool check(MoveCheckArgs args) {
    final cardsOnPile = args.table.get(args.pile);

    return args.cards.isSingle &&
        cardsOnPile.isNotEmpty &&
        cardsOnPile.last == args.cards.single;
  }
}

class CardsFollowRankOrder extends MoveCheck {
  const CardsFollowRankOrder(this.rankOrder, {this.wrapping = false});

  final RankOrder rankOrder;

  final bool wrapping;

  @override
  String get errorMessage => 'Cards must follow rank order, ${rankOrder.name}';

  @override
  bool check(MoveCheckArgs args) {
    return args.cards.isSortedByRank(rankOrder, wrapping: wrapping);
  }
}

class CardsAreSameSuit extends MoveCheck {
  const CardsAreSameSuit();

  @override
  String get errorMessage => 'Cards must all be in same suit';

  @override
  bool check(MoveCheckArgs args) {
    if (args.cards.isEmpty || args.cards.isSingle) {
      return true;
    }

    final referenceSuit = args.cards.first.suit;
    return args.cards.every((c) => c.suit == referenceSuit);
  }
}

class CardsAreAlternatingColors extends MoveCheck {
  const CardsAreAlternatingColors();

  @override
  String get errorMessage => 'Cards must all be in alternating colors';

  @override
  bool check(MoveCheckArgs args) {
    final cardsInHand = args.cards;

    if (cardsInHand.isEmpty || cardsInHand.isSingle) {
      return true;
    }

    for (int i = 1; i < cardsInHand.length; i++) {
      if (cardsInHand[i].suit.color == cardsInHand[i - 1].suit.color) {
        return false;
      }
    }
    return true;
  }
}

class CardsComingFrom<T extends Pile> extends MoveCheck {
  const CardsComingFrom();

  @override
  String get errorMessage => 'Cards must come from $T';

  @override
  bool check(MoveCheckArgs args) {
    return args.originPile is T;
  }
}

class CardsNotComingFrom<T extends Pile> extends MoveCheck {
  const CardsNotComingFrom();

  @override
  String get errorMessage => 'Cards must not come from $T';

  @override
  bool check(MoveCheckArgs args) {
    return args.originPile is! T;
  }
}

class BuildupStartsWith extends MoveCheck {
  const BuildupStartsWith(Rank this.rank)
      : referencePiles = null,
        rankDifference = 0,
        wrapping = false;

  /// Used by Penguin and the like
  const BuildupStartsWith.relativeTo(
    List<Pile> this.referencePiles, {
    this.rankDifference = 0,
    this.wrapping = false,
  }) : rank = null;

  final Rank? rank;

  final List<Pile>? referencePiles;

  final int rankDifference;

  final bool wrapping;

  bool get isRelative => referencePiles != null;

  @override
  String get errorMessage {
    if (rank != null) {
      return 'Buildup must start with ${rank!.name.toCapitalCase()}';
    } else {
      // TODO: Find out how to customize a constant error message
      return 'Buildup must start with the indicated rank';
    }
  }

  @override
  bool check(MoveCheckArgs args) {
    // If cards are already filled, ignore. This check is only for unfilled pile anyway
    final cardsOnPile = args.table.get(args.pile);
    if (cardsOnPile.isNotEmpty) {
      return true;
    }

    final firstCardInHand = args.cards.first;

    if (rank != null) {
      return firstCardInHand.rank == rank;
    } else if (referencePiles != null) {
      final firstRefPile = referencePiles!
          .firstWhereOrNull((pile) => args.table.get(pile).isNotEmpty);

      // All reference piles are not filled yet, accept them
      if (firstRefPile == null) {
        return true;
      }
      final cardsOnRefPile = args.table.get(firstRefPile);

      return firstCardInHand.rank ==
          cardsOnRefPile.first.rank
              .next(gap: rankDifference, wrapping: wrapping);
    } else {
      throw AssertionError();
    }
  }
}

class BuildupFollowsRankOrder extends MoveCheck {
  const BuildupFollowsRankOrder(this.rankOrder, {this.wrapping = false});

  final RankOrder rankOrder;

  final bool wrapping;

  @override
  String get errorMessage =>
      'Buildup must follow rank order, ${rankOrder.name}';

  @override
  bool check(MoveCheckArgs args) {
    final cardsOnPile = args.table.get(args.pile);

    if (cardsOnPile.isEmpty || args.cards.isEmpty) {
      return true;
    }

    return switch (rankOrder) {
      RankOrder.increasing =>
        cardsOnPile.last.isOneRankUnder(args.cards.first, wrapping: wrapping),
      RankOrder.decreasing =>
        cardsOnPile.last.isOneRankOver(args.cards.first, wrapping: wrapping),
    };
  }
}

class BuildupOneRankNearer extends MoveCheck {
  const BuildupOneRankNearer({this.wrapping = false});

  final bool wrapping;

  @override
  String get errorMessage => 'Buildup must be one rank higher or lower';

  @override
  bool check(MoveCheckArgs args) {
    final cardsOnPile = args.table.get(args.pile);

    if (cardsOnPile.isEmpty || args.cards.isEmpty) {
      return true;
    }

    return cardsOnPile.last
        .isOneRankNearer(args.cards.first, wrapping: wrapping);
  }
}

class BuildupAlternatingColors extends MoveCheck {
  const BuildupAlternatingColors();

  @override
  String get errorMessage => 'Buildup must alternate between colors';

  @override
  bool check(MoveCheckArgs args) {
    final cardsOnPile = args.table.get(args.pile);

    if (cardsOnPile.isEmpty || args.cards.isEmpty) {
      return true;
    }

    return !cardsOnPile.last.isSameColor(args.cards.first);
  }
}

class BuildupSameSuit extends MoveCheck {
  const BuildupSameSuit();

  @override
  String get errorMessage => 'Buildup must be in same suit';

  @override
  bool check(MoveCheckArgs args) {
    final cardsOnPile = args.table.get(args.pile);

    if (cardsOnPile.isEmpty || args.cards.isEmpty) {
      return true;
    }

    return cardsOnPile.last.suit == args.cards.first.suit;
  }
}

class BuildupRankAbove extends MoveCheck {
  const BuildupRankAbove({
    required this.gap,
    this.wrapping = false,
  }) : assert(gap > 0);

  final int gap;
  final bool wrapping;

  @override
  String get errorMessage => 'Buildup must be $gap rank(s) above';

  @override
  bool check(MoveCheckArgs args) {
    final cardsOnPile = args.table.get(args.pile);

    if (cardsOnPile.isEmpty || args.cards.isEmpty) {
      return true;
    }

    return cardsOnPile.last.rank.next(gap: gap, wrapping: wrapping) ==
        args.cards.first.rank;
  }
}

class PileIsEmpty extends MoveCheck {
  const PileIsEmpty();

  @override
  String get errorMessage => 'Pile must be empty';

  @override
  bool check(MoveCheckArgs args) {
    return args.table.get(args.pile).isEmpty;
  }
}

class PileIsNotEmpty extends MoveCheck {
  const PileIsNotEmpty();

  @override
  String get errorMessage => 'Pile must not be empty';

  @override
  bool check(MoveCheckArgs args) {
    return args.table.get(args.pile).isNotEmpty;
  }
}

class PileIsNotSingle extends MoveCheck {
  const PileIsNotSingle();

  @override
  String get errorMessage => 'Cards on pile must not be single';

  @override
  bool check(MoveCheckArgs args) {
    return args.table.get(args.pile).length != 1;
  }
}

class PileHasLength extends MoveCheck {
  const PileHasLength(this.length);

  final int length;

  @override
  String get errorMessage => 'Pile must have $length card(s)';

  @override
  bool check(MoveCheckArgs args) {
    return args.table.get(args.pile).length == length;
  }
}

class PileIsAllFacingUp extends MoveCheck {
  const PileIsAllFacingUp();

  @override
  String get errorMessage => 'Cards on pile must all be facing up';

  @override
  bool check(MoveCheckArgs args) {
    return args.table.get(args.pile).isAllFacingUp;
  }
}

class PileTopCardIsFacingDown extends MoveCheck {
  const PileTopCardIsFacingDown();

  @override
  String get errorMessage => 'Cards on pile must all be facing down';

  @override
  bool check(MoveCheckArgs args) {
    final cardsOnPile = args.table.get(args.pile);
    return cardsOnPile.isNotEmpty && cardsOnPile.last.isFacingDown;
  }
}

class PileTopCardIsRank extends MoveCheck {
  const PileTopCardIsRank(this.rank);

  final Rank rank;

  @override
  String get errorMessage =>
      'Cards on pile must be ${rank.name.toCapitalCase()}';

  @override
  bool check(MoveCheckArgs args) {
    final cardsOnPile = args.table.get(args.pile);
    return cardsOnPile.isNotEmpty && cardsOnPile.last.rank == rank;
  }
}

class PileTopCardIsNotRank extends MoveCheck {
  const PileTopCardIsNotRank(this.rank);

  final Rank rank;

  @override
  String get errorMessage =>
      'Cards on pile must not be ${rank.name.toCapitalCase()}';

  @override
  bool check(MoveCheckArgs args) {
    final cardsOnPile = args.table.get(args.pile);
    return cardsOnPile.isNotEmpty && cardsOnPile.last.rank != rank;
  }
}

class NotAllowed extends MoveCheck {
  const NotAllowed();

  @override
  String get errorMessage => 'Move is not allowed';

  @override
  bool check(MoveCheckArgs args) {
    return false;
  }
}

class AllPilesOfType<T extends Pile> extends MoveCheck {
  const AllPilesOfType(this.checkPerPile);

  final List<MoveCheck> checkPerPile;

  // TODO: Implement
  @override
  String get errorMessage => '';

  @override
  bool check(MoveCheckArgs args) {
    return args.table.allPilesOfType<T>().every((p) {
      return checkPerPile.every((c) => c.check(args.copyWith(pile: p)));
    });
  }
}

class AllPilesOf<T extends Pile> extends MoveCheck {
  const AllPilesOf(this.piles, this.checkPerPile);

  final List<T> piles;
  final List<MoveCheck> checkPerPile;

  // TODO: Implement
  @override
  String get errorMessage => '';

  @override
  bool check(MoveCheckArgs args) {
    return piles.every((p) {
      return checkPerPile.every((c) => c.check(args.copyWith(pile: p)));
    });
  }
}

/// http://www.solitairecentral.com/articles/FreecellPowerMovesExplained.html
class FreeCellPowermove extends MoveCheck {
  const FreeCellPowermove();

  @override
  String get errorMessage => 'Not enough free cells to move the cards';

  @override
  bool check(MoveCheckArgs args) {
    final numberOfEmptyTableaus = args.table
        .allPilesOfType<Tableau>()
        .count((t) => t != args.pile && args.table.get(t).isEmpty);
    final numberOfEmptyReserves = args.table
        .allPilesOfType<Reserve>()
        .count((r) => args.table.get(r).isEmpty);

    final movableCardsLength =
        (1 + numberOfEmptyReserves) * pow(2, numberOfEmptyTableaus);
    return args.cards.length <= movableCardsLength;
  }
}

class PileHasFullSuit extends MoveCheck {
  const PileHasFullSuit({this.rankOrder});

  final RankOrder? rankOrder;

  @override
  String get errorMessage => 'Pile must have full set of suits';

  @override
  bool check(MoveCheckArgs args) {
    final cardsOnPile = args.table.get(args.pile).getLast(Rank.values.length);

    if (cardsOnPile.length != Rank.values.length) {
      return false;
    }

    if (rankOrder != null) {
      return cardsOnPile.isSortedByRank(rankOrder!);
    }
    return true;
  }
}

class CardsHasFullSuit extends MoveCheck {
  const CardsHasFullSuit(this.rankOrder);

  final RankOrder rankOrder;

  @override
  String get errorMessage => 'Cards must have full set of suits';

  @override
  bool check(MoveCheckArgs args) {
    if (args.cards.length != Rank.values.length) {
      return false;
    }
    return args.cards.isSortedByRank(rankOrder);
  }
}

class CanRecyclePile extends MoveCheck {
  const CanRecyclePile({this.limit, required this.willTakeFrom});

  final int? limit;

  final Pile willTakeFrom;

  @override
  String get errorMessage => 'Cannot recycle pile anymore';

  @override
  bool check(MoveCheckArgs args) {
    if (limit == null) {
      return true;
    }

    // Ignore if pile is not empty
    if (args.table.get(args.pile).isNotEmpty) {
      return true;
    }

    if (args.table.get(willTakeFrom).isEmpty) {
      return false;
    }

    final currentCycle = args.moveState?.recycleCounts[args.pile] ?? 0;

    return currentCycle < limit! - 1;
  }
}

class PileIsExposed extends MoveCheck {
  const PileIsExposed();

  @override
  String get errorMessage => 'Card is not exposed';

  @override
  bool check(MoveCheckArgs args) {
    if (args.pile is! Grid) {
      return false;
    }

    final grid = args.pile as Grid;
    final (x, y) = grid.xy;

    final cardsOnBottomLeft = args.table.get(Grid(x, y + 1));
    final cardsOnBottomRight = args.table.get(Grid(x + 1, y + 1));

    return cardsOnBottomLeft.isEmpty && cardsOnBottomRight.isEmpty;
  }
}

class BuildupRankValueAddUpTo extends MoveCheck {
  const BuildupRankValueAddUpTo(this.targetValue);

  final int targetValue;

  @override
  String get errorMessage => 'Buildup rank value must add up to $targetValue';

  @override
  bool check(MoveCheckArgs args) {
    // Check card on pile and in hands, ensure they are not empty
    if (args.table.get(args.pile).isEmpty || args.cards.isEmpty) {
      return false;
    }

    final cardOnTable = args.table.get(args.pile).last;
    final cardInHand = args.cards.first;

    return cardOnTable.rank.value + cardInHand.rank.value == targetValue;
  }
}

class CardsRankValueAddUpTo extends MoveCheck {
  const CardsRankValueAddUpTo(this.targetValue);

  final int targetValue;

  @override
  String get errorMessage => 'Cards\' rank value must add up to $targetValue';

  @override
  bool check(MoveCheckArgs args) {
    if (args.cards.isEmpty) {
      return false;
    }

    return args.cards.map((card) => card.rank.value).sum == targetValue;
  }
}
