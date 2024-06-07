import 'dart:math';

import '../utils/types.dart';
import 'card.dart';
import 'card_list.dart';
import 'pile.dart';
import 'play_table.dart';
import 'rank_order.dart';

abstract class PileCheck {
  const PileCheck();

  bool check(Pile pile, List<PlayCard> cards, PlayTable table);

  static PileCheckResult checkAll(
    List<PileCheck>? checks,
    Pile pile,
    List<PlayCard> cards,
    PlayTable table,
  ) {
    if (checks == null) {
      return const PileCheckFail(reason: null);
    }
    for (final item in checks) {
      if (!item.check(pile, cards, table)) {
        return PileCheckFail(reason: item);
      }
    }
    return const PileCheckOK();
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
  bool check(Pile pile, List<PlayCard> cards, PlayTable table) {
    return cards.isAllFacingUp;
  }
}

class CardIsSingle extends PileCheck {
  const CardIsSingle();

  @override
  bool check(Pile pile, List<PlayCard> cards, PlayTable table) {
    return cards.isSingle;
  }
}

class CardIsOnTop extends PileCheck {
  const CardIsOnTop();

  @override
  bool check(Pile pile, List<PlayCard> cards, PlayTable table) {
    final cardsOnPile = table.get(pile);

    return cards.isSingle &&
        cardsOnPile.isNotEmpty &&
        cardsOnPile.last == cards.single;
  }
}

class CardsFollowRankOrder extends PileCheck {
  const CardsFollowRankOrder(this.rankOrder);

  final RankOrder rankOrder;

  @override
  bool check(Pile pile, List<PlayCard> cards, PlayTable table) {
    return switch (rankOrder) {
      RankOrder.increasing => cards.isSortedByRankIncreasingOrder,
      RankOrder.decreasing => cards.isSortedByRankDecreasingOrder,
    };
  }
}

class CardsAreSameSuit extends PileCheck {
  const CardsAreSameSuit();

  @override
  bool check(Pile pile, List<PlayCard> cards, PlayTable table) {
    if (cards.isEmpty || cards.isSingle) {
      return true;
    }

    final referenceSuit = cards.first.suit;
    return cards.every((c) => c.suit == referenceSuit);
  }
}

class BuildupStartsWith extends PileCheck {
  const BuildupStartsWith({this.rank, this.suit});

  final Rank? rank;
  final Suit? suit;

  @override
  bool check(Pile pile, List<PlayCard> cards, PlayTable table) {
    final cardsOnPile = table.get(pile);

    if (cardsOnPile.isNotEmpty) {
      return true;
    }

    final firstCardInHand = cards.first;
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
  bool check(Pile pile, List<PlayCard> cards, PlayTable table) {
    final cardsOnPile = table.get(pile);

    if (cardsOnPile.isEmpty || cards.isEmpty) {
      return true;
    }

    return switch (rankOrder) {
      RankOrder.increasing => cardsOnPile.last.isOneRankUnder(cards.first),
      RankOrder.decreasing => cardsOnPile.last.isOneRankOver(cards.first),
    };
  }
}

class BuildupAlternateColors extends PileCheck {
  const BuildupAlternateColors();

  @override
  bool check(Pile pile, List<PlayCard> cards, PlayTable table) {
    final cardsOnPile = table.get(pile);

    if (cardsOnPile.isEmpty || cards.isEmpty) {
      return true;
    }

    return !cardsOnPile.last.isSameColor(cards.first);
  }
}

class BuildupSameSuit extends PileCheck {
  const BuildupSameSuit();

  @override
  bool check(Pile pile, List<PlayCard> cards, PlayTable table) {
    final cardsOnPile = table.get(pile);

    if (cardsOnPile.isEmpty || cards.isEmpty) {
      return true;
    }

    return cardsOnPile.last.suit == cards.first.suit;
  }
}
//
// class CardsComingFrom extends PileCheck {
//   const CardsComingFrom(this.originPile);
//
//   final Pile originPile;
//
//   @override
//   bool check(Pile pile, List<PlayCard> cards, PlayTable table) {
//     return from != null && from == originPile;
//   }
// }
//
// class CardsNotComingFrom extends PileCheck {
//   const CardsNotComingFrom(this.originPile);
//
//   final Pile originPile;
//
//   @override
//   bool check(Pile pile, List<PlayCard> cards, PlayTable table) {
//     return from != null && from != originPile;
//   }
// }

class PileIsEmpty extends PileCheck {
  const PileIsEmpty();

  @override
  bool check(Pile pile, List<PlayCard> cards, PlayTable table) {
    return table.get(pile).isEmpty;
  }
}

class PileIsNotEmpty extends PileCheck {
  const PileIsNotEmpty();

  @override
  bool check(Pile pile, List<PlayCard> cards, PlayTable table) {
    return table.get(pile).isNotEmpty;
  }
}

class PileTopCardIsFacingDown extends PileCheck {
  const PileTopCardIsFacingDown();

  @override
  bool check(Pile pile, List<PlayCard> cards, PlayTable table) {
    final cardsOnPile = table.get(pile);
    return cardsOnPile.isNotEmpty && cardsOnPile.last.isFacingDown;
  }
}

class RejectAll extends PileCheck {
  const RejectAll();

  @override
  bool check(Pile pile, List<PlayCard> cards, PlayTable table) {
    return false;
  }
}

class AllPilesOfTypeAreNotEmpty<T extends Pile> extends PileCheck {
  const AllPilesOfTypeAreNotEmpty();

  @override
  bool check(Pile pile, List<PlayCard> cards, PlayTable table) {
    return table.allPilesOfType<T>().every((p) => table.get(p).isNotEmpty);
  }
}

class AllPilesOfTypeHaveFullSuit<T extends Pile> extends PileCheck {
  const AllPilesOfTypeHaveFullSuit(this.rankOrder);

  final RankOrder rankOrder;

  @override
  bool check(Pile pile, List<PlayCard> cards, PlayTable table) {
    return table.allPilesOfType<T>().every((p) {
      return PileHasFullSuit(rankOrder).check(p, cards, table);
    });
  }
}

/// http://www.solitairecentral.com/articles/FreecellPowerMovesExplained.html
class FreeCellPowermove extends PileCheck {
  const FreeCellPowermove();

  @override
  bool check(Pile pile, List<PlayCard> cards, PlayTable table) {
    final numberOfEmptyTableaus = table
        .allPilesOfType<Tableau>()
        .count((t) => t != pile && table.get(t).isEmpty);
    final numberOfEmptyReserves =
        table.allPilesOfType<Reserve>().count((r) => table.get(r).isEmpty);

    final movableCardsLength =
        (1 + numberOfEmptyReserves) * pow(2, numberOfEmptyTableaus);
    return cards.length <= movableCardsLength;
  }
}

class PileHasFullSuit extends PileCheck {
  const PileHasFullSuit(this.rankOrder);

  final RankOrder rankOrder;

  @override
  bool check(Pile pile, List<PlayCard> cards, PlayTable table) {
    final cardsOnPile = table.get(pile).getLast(Rank.values.length);

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
  bool check(Pile pile, List<PlayCard> cards, PlayTable table) {
    if (cards.length != Rank.values.length) {
      return false;
    }

    return switch (rankOrder) {
      RankOrder.increasing => cards.isSortedByRankIncreasingOrder,
      RankOrder.decreasing => cards.isSortedByRankDecreasingOrder,
    };
  }
}
