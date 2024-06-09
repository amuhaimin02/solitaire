import 'dart:math';

import 'package:change_case/change_case.dart';
import 'package:collection/collection.dart';

import '../utils/types.dart';
import 'card.dart';
import 'card_list.dart';
import 'move_record.dart';
import 'pile.dart';
import 'play_table.dart';
import 'rank_order.dart';

abstract class MoveCheck {
  const MoveCheck();

  bool check(MoveCheckData data);

  String get errorMessage;

  static MoveCheckResult checkAll(
    List<MoveCheck>? checks,
    MoveCheckData data,
  ) {
    if (checks == null) {
      return const MoveCheckFail(reason: null);
    }
    for (final item in checks) {
      if (!item.check(data)) {
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
  bool check(MoveCheckData data) {
    return check1.check(data) || check2.check(data);
  }
}

class MoveCheckData {
  final Pile pile;
  final List<PlayCard> cards;
  final PlayTable table;
  final MoveState? moveState;

  MoveCheckData({
    required this.pile,
    this.cards = const [],
    required this.table,
    this.moveState,
  });

  MoveCheckData withPile(Pile newPile) {
    return MoveCheckData(
      pile: newPile,
      cards: cards,
      table: table,
      moveState: moveState,
    );
  }
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

class CardsAreFacingUp extends MoveCheck {
  const CardsAreFacingUp();

  @override
  String get errorMessage => 'Cards must all be facing up';
  @override
  bool check(MoveCheckData data) {
    return data.cards.isAllFacingUp;
  }
}

class CardIsSingle extends MoveCheck {
  const CardIsSingle();

  @override
  String get errorMessage => 'Only a single card is allowed';

  @override
  bool check(MoveCheckData data) {
    return data.cards.isSingle;
  }
}

class CardIsOnTop extends MoveCheck {
  const CardIsOnTop();

  @override
  String get errorMessage => 'Card is not on top';

  @override
  bool check(MoveCheckData data) {
    final cardsOnPile = data.table.get(data.pile);

    return data.cards.isSingle &&
        cardsOnPile.isNotEmpty &&
        cardsOnPile.last == data.cards.single;
  }
}

class CardsFollowRankOrder extends MoveCheck {
  const CardsFollowRankOrder(this.rankOrder, {this.wrapping = false});

  final RankOrder rankOrder;

  final bool wrapping;

  @override
  String get errorMessage => 'Cards must follow rank order, ${rankOrder.name}';

  @override
  bool check(MoveCheckData data) {
    return data.cards.isSortedByRank(rankOrder, wrapping: wrapping);
  }
}

class CardsAreSameSuit extends MoveCheck {
  const CardsAreSameSuit();

  @override
  String get errorMessage => 'Cards must all be in same suit';

  @override
  bool check(MoveCheckData data) {
    if (data.cards.isEmpty || data.cards.isSingle) {
      return true;
    }

    final referenceSuit = data.cards.first.suit;
    return data.cards.every((c) => c.suit == referenceSuit);
  }
}

class CardsAreAlternatingColors extends MoveCheck {
  const CardsAreAlternatingColors();

  @override
  String get errorMessage => 'Cards must all be in alternating colors';

  @override
  bool check(MoveCheckData data) {
    final cardsInHand = data.cards;

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

class BuildupStartsWith extends MoveCheck {
  const BuildupStartsWith(Rank this.rank)
      : referencePiles = null,
        rankDifference = 0;

  /// Used by Penguin and the like
  const BuildupStartsWith.relativeTo(
    List<Pile> this.referencePiles, {
    this.rankDifference = 0,
  }) : rank = null;

  final Rank? rank;

  final List<Pile>? referencePiles;

  final int rankDifference;

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
  bool check(MoveCheckData data) {
    // If cards are already filled, ignore. This check is only for unfilled pile anyway
    final cardsOnPile = data.table.get(data.pile);
    if (cardsOnPile.isNotEmpty) {
      return true;
    }

    final firstCardInHand = data.cards.first;

    if (rank != null) {
      return firstCardInHand.rank == rank;
    } else if (referencePiles != null) {
      final firstRefPile = referencePiles!
          .firstWhereOrNull((pile) => data.table.get(pile).isNotEmpty);

      // All reference piles are not filled yet, accept them
      if (firstRefPile == null) {
        return true;
      }
      final cardsOnRefPile = data.table.get(firstRefPile);

      return firstCardInHand.rank ==
          cardsOnRefPile.first.rank.next(gap: rankDifference);
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
  bool check(MoveCheckData data) {
    final cardsOnPile = data.table.get(data.pile);

    if (cardsOnPile.isEmpty || data.cards.isEmpty) {
      return true;
    }

    return switch (rankOrder) {
      RankOrder.increasing =>
        cardsOnPile.last.isOneRankUnder(data.cards.first, wrapping: wrapping),
      RankOrder.decreasing =>
        cardsOnPile.last.isOneRankOver(data.cards.first, wrapping: wrapping),
    };
  }
}

class BuildupOneRankNearer extends MoveCheck {
  // TODO: Support wrapping
  const BuildupOneRankNearer();

  @override
  String get errorMessage => 'Buildup must be one rank higher or lower';

  @override
  bool check(MoveCheckData data) {
    final cardsOnPile = data.table.get(data.pile);

    if (cardsOnPile.isEmpty || data.cards.isEmpty) {
      return true;
    }

    return cardsOnPile.last.isOneRankNearer(data.cards.first);
  }
}

class BuildupAlternatingColors extends MoveCheck {
  const BuildupAlternatingColors();

  @override
  String get errorMessage => 'Buildup must alternate between colors';

  @override
  bool check(MoveCheckData data) {
    final cardsOnPile = data.table.get(data.pile);

    if (cardsOnPile.isEmpty || data.cards.isEmpty) {
      return true;
    }

    return !cardsOnPile.last.isSameColor(data.cards.first);
  }
}

class BuildupSameSuit extends MoveCheck {
  const BuildupSameSuit();

  @override
  String get errorMessage => 'Buildup must be in same suit';

  @override
  bool check(MoveCheckData data) {
    final cardsOnPile = data.table.get(data.pile);

    if (cardsOnPile.isEmpty || data.cards.isEmpty) {
      return true;
    }

    return cardsOnPile.last.suit == data.cards.first.suit;
  }
}

class PileIsEmpty extends MoveCheck {
  const PileIsEmpty();

  @override
  String get errorMessage => 'Pile must be empty';

  @override
  bool check(MoveCheckData data) {
    return data.table.get(data.pile).isEmpty;
  }
}

class PileIsNotEmpty extends MoveCheck {
  const PileIsNotEmpty();

  @override
  String get errorMessage => 'Pile must not be empty';

  @override
  bool check(MoveCheckData data) {
    return data.table.get(data.pile).isNotEmpty;
  }
}

class PileIsAllFacingUp extends MoveCheck {
  const PileIsAllFacingUp();

  @override
  String get errorMessage => 'Cards on pile must all be facing up';

  @override
  bool check(MoveCheckData data) {
    return data.table.get(data.pile).isAllFacingUp;
  }
}

class PileTopCardIsFacingDown extends MoveCheck {
  const PileTopCardIsFacingDown();

  @override
  String get errorMessage => 'Cards on pile must all be facing down';

  @override
  bool check(MoveCheckData data) {
    final cardsOnPile = data.table.get(data.pile);
    return cardsOnPile.isNotEmpty && cardsOnPile.last.isFacingDown;
  }
}

class NotAllowed extends MoveCheck {
  const NotAllowed();

  @override
  String get errorMessage => 'Move is not allowed';

  @override
  bool check(MoveCheckData data) {
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
  bool check(MoveCheckData data) {
    return data.table.allPilesOfType<T>().every((p) {
      return checkPerPile.every((c) => c.check(data.withPile(p)));
    });
  }
}

/// http://www.solitairecentral.com/articles/FreecellPowerMovesExplained.html
class FreeCellPowermove extends MoveCheck {
  const FreeCellPowermove();

  @override
  String get errorMessage => 'Not enough free cells to move the cards';

  @override
  bool check(MoveCheckData data) {
    final numberOfEmptyTableaus = data.table
        .allPilesOfType<Tableau>()
        .count((t) => t != data.pile && data.table.get(t).isEmpty);
    final numberOfEmptyReserves = data.table
        .allPilesOfType<Reserve>()
        .count((r) => data.table.get(r).isEmpty);

    final movableCardsLength =
        (1 + numberOfEmptyReserves) * pow(2, numberOfEmptyTableaus);
    return data.cards.length <= movableCardsLength;
  }
}

class PileHasFullSuit extends MoveCheck {
  const PileHasFullSuit({this.rankOrder});

  final RankOrder? rankOrder;

  @override
  String get errorMessage => 'Pile must have full set of suits';

  @override
  bool check(MoveCheckData data) {
    final cardsOnPile = data.table.get(data.pile).getLast(Rank.values.length);

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
  bool check(MoveCheckData data) {
    if (data.cards.length != Rank.values.length) {
      return false;
    }
    return data.cards.isSortedByRank(rankOrder);
  }
}

class CanRecyclePile extends MoveCheck {
  const CanRecyclePile({this.limit, required this.willTakeFrom});

  final int? limit;

  final Pile willTakeFrom;

  @override
  String get errorMessage => 'Cannot recycle pile anymore';

  @override
  bool check(MoveCheckData data) {
    if (limit == null) {
      return true;
    }

    // Ignore if pile is not empty
    if (data.table.get(data.pile).isNotEmpty) {
      return true;
    }

    if (data.table.get(willTakeFrom).isEmpty) {
      return false;
    }

    final currentCycle = data.moveState?.recycleCounts[data.pile] ?? 0;

    return currentCycle < limit! - 1;
  }
}
