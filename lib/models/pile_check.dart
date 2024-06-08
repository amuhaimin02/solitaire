import 'dart:math';

import '../utils/types.dart';
import 'card.dart';
import 'card_list.dart';
import 'move_record.dart';
import 'pile.dart';
import 'play_table.dart';
import 'rank_order.dart';

abstract class PileCheck {
  const PileCheck();

  bool check(PileCheckData data);

  static PileCheckResult checkAll(
    List<PileCheck>? checks,
    PileCheckData data,
  ) {
    if (checks == null) {
      return const PileCheckFail(reason: null);
    }
    for (final item in checks) {
      if (!item.check(data)) {
        return PileCheckFail(reason: item);
      }
    }
    return const PileCheckOK();
  }

  PileCheck operator |(PileCheck other) {
    return _PileCheckOr(this, other);
  }
}

class _PileCheckOr extends PileCheck {
  const _PileCheckOr(this.check1, this.check2);

  final PileCheck check1;
  final PileCheck check2;

  @override
  bool check(PileCheckData data) {
    return check1.check(data) || check2.check(data);
  }
}

class PileCheckData {
  final Pile pile;
  final List<PlayCard> cards;
  final PlayTable table;
  final MoveState? moveState;

  PileCheckData({
    required this.pile,
    this.cards = const [],
    required this.table,
    this.moveState,
  });

  PileCheckData withPile(Pile newPile) {
    return PileCheckData(
      pile: newPile,
      cards: cards,
      table: table,
      moveState: moveState,
    );
  }
}

sealed class PileCheckResult {
  const PileCheckResult();
}

class PileCheckOK extends PileCheckResult {
  const PileCheckOK();
}

class PileCheckFail extends PileCheckResult {
  const PileCheckFail({required this.reason});

  final PileCheck? reason;
}

class CardsAreFacingUp extends PileCheck {
  const CardsAreFacingUp();

  @override
  bool check(PileCheckData data) {
    return data.cards.isAllFacingUp;
  }
}

class CardIsSingle extends PileCheck {
  const CardIsSingle();

  @override
  bool check(PileCheckData data) {
    return data.cards.isSingle;
  }
}

class CardIsOnTop extends PileCheck {
  const CardIsOnTop();

  @override
  bool check(PileCheckData data) {
    final cardsOnPile = data.table.get(data.pile);

    return data.cards.isSingle &&
        cardsOnPile.isNotEmpty &&
        cardsOnPile.last == data.cards.single;
  }
}

class CardsFollowRankOrder extends PileCheck {
  const CardsFollowRankOrder(this.rankOrder);

  final RankOrder rankOrder;

  @override
  bool check(PileCheckData data) {
    return switch (rankOrder) {
      RankOrder.increasing => data.cards.isSortedByRankIncreasingOrder,
      RankOrder.decreasing => data.cards.isSortedByRankDecreasingOrder,
    };
  }
}

class CardsAreSameSuit extends PileCheck {
  const CardsAreSameSuit();

  @override
  bool check(PileCheckData data) {
    if (data.cards.isEmpty || data.cards.isSingle) {
      return true;
    }

    final referenceSuit = data.cards.first.suit;
    return data.cards.every((c) => c.suit == referenceSuit);
  }
}

class BuildupStartsWith extends PileCheck {
  const BuildupStartsWith({this.rank, this.suit});

  final Rank? rank;
  final Suit? suit;

  @override
  bool check(PileCheckData data) {
    final cardsOnPile = data.table.get(data.pile);

    if (cardsOnPile.isNotEmpty) {
      return true;
    }

    final firstCardInHand = data.cards.first;
    if (rank != null && firstCardInHand.rank != rank) {
      return false;
    }
    if (suit != null && firstCardInHand.suit != suit) {
      return false;
    }
    return true;
  }
}

class BuildupFollowsRankOrder extends PileCheck {
  const BuildupFollowsRankOrder(this.rankOrder);

  final RankOrder rankOrder;

  @override
  bool check(PileCheckData data) {
    final cardsOnPile = data.table.get(data.pile);

    if (cardsOnPile.isEmpty || data.cards.isEmpty) {
      return true;
    }

    return switch (rankOrder) {
      RankOrder.increasing => cardsOnPile.last.isOneRankUnder(data.cards.first),
      RankOrder.decreasing => cardsOnPile.last.isOneRankOver(data.cards.first),
    };
  }
}

class BuildupAlternateColors extends PileCheck {
  const BuildupAlternateColors();

  @override
  bool check(PileCheckData data) {
    final cardsOnPile = data.table.get(data.pile);

    if (cardsOnPile.isEmpty || data.cards.isEmpty) {
      return true;
    }

    return !cardsOnPile.last.isSameColor(data.cards.first);
  }
}

class BuildupSameSuit extends PileCheck {
  const BuildupSameSuit();

  @override
  bool check(PileCheckData data) {
    final cardsOnPile = data.table.get(data.pile);

    if (cardsOnPile.isEmpty || data.cards.isEmpty) {
      return true;
    }

    return cardsOnPile.last.suit == data.cards.first.suit;
  }
}

class PileIsEmpty extends PileCheck {
  const PileIsEmpty();

  @override
  bool check(PileCheckData data) {
    return data.table.get(data.pile).isEmpty;
  }
}

class PileIsNotEmpty extends PileCheck {
  const PileIsNotEmpty();

  @override
  bool check(PileCheckData data) {
    return data.table.get(data.pile).isNotEmpty;
  }
}

class PileIsAllFacingUp extends PileCheck {
  const PileIsAllFacingUp();

  @override
  bool check(PileCheckData data) {
    return data.table.get(data.pile).isAllFacingUp;
  }
}

class PileTopCardIsFacingDown extends PileCheck {
  const PileTopCardIsFacingDown();

  @override
  bool check(PileCheckData data) {
    final cardsOnPile = data.table.get(data.pile);
    return cardsOnPile.isNotEmpty && cardsOnPile.last.isFacingDown;
  }
}

class RejectAll extends PileCheck {
  const RejectAll();

  @override
  bool check(PileCheckData data) {
    return false;
  }
}

class AllPilesOfType<T extends Pile> extends PileCheck {
  const AllPilesOfType(this.checkPerPile);

  final List<PileCheck> checkPerPile;

  @override
  bool check(PileCheckData data) {
    return data.table.allPilesOfType<T>().every((p) {
      return checkPerPile.every((c) => c.check(data.withPile(p)));
    });
  }
}

/// http://www.solitairecentral.com/articles/FreecellPowerMovesExplained.html
class FreeCellPowermove extends PileCheck {
  const FreeCellPowermove();

  @override
  bool check(PileCheckData data) {
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

class PileHasFullSuit extends PileCheck {
  const PileHasFullSuit(this.rankOrder);

  final RankOrder rankOrder;

  @override
  bool check(PileCheckData data) {
    final cardsOnPile = data.table.get(data.pile).getLast(Rank.values.length);

    if (cardsOnPile.length != Rank.values.length) {
      return false;
    }

    return switch (rankOrder) {
      RankOrder.increasing => cardsOnPile.isSortedByRankIncreasingOrder,
      RankOrder.decreasing => cardsOnPile.isSortedByRankDecreasingOrder,
    };
  }
}

class CardsHasFullSuit extends PileCheck {
  const CardsHasFullSuit(this.rankOrder);

  final RankOrder rankOrder;

  @override
  bool check(PileCheckData data) {
    if (data.cards.length != Rank.values.length) {
      return false;
    }

    return switch (rankOrder) {
      RankOrder.increasing => data.cards.isSortedByRankIncreasingOrder,
      RankOrder.decreasing => data.cards.isSortedByRankDecreasingOrder,
    };
  }
}

class CanRecyclePile extends PileCheck {
  const CanRecyclePile({required this.limit});

  final int limit;

  @override
  bool check(PileCheckData data) {
    // Ignore if pile is not empty
    if (data.table.get(data.pile).isNotEmpty) {
      return true;
    }

    final currentCycle = data.moveState?.recycleCounts[data.pile] ?? 0;

    return currentCycle < limit - 1;
  }
}
