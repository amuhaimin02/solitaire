import 'card.dart';
import 'card_list.dart';
import 'pile.dart';
import 'play_table.dart';

enum RankOrder { increasing, decreasing }

abstract class PileCheck {
  const PileCheck();

  bool check(Pile pile, Pile? from, List<PlayCard> cards, PlayTable table);

  static bool checkAll(List<PileCheck>? checks, Pile pile, Pile? from,
      List<PlayCard> cards, PlayTable table) {
    return checks?.every((item) => item.check(pile, from, cards, table)) ==
        true;
  }
}

class CardsAreFacingUp extends PileCheck {
  const CardsAreFacingUp();

  @override
  bool check(Pile pile, Pile? from, List<PlayCard> cards, PlayTable table) {
    return cards.isAllFacingUp;
  }
}

class CardIsSingle extends PileCheck {
  const CardIsSingle();

  @override
  bool check(Pile pile, Pile? from, List<PlayCard> cards, PlayTable table) {
    return cards.isSingle;
  }
}

class CardIsOnTop extends PileCheck {
  const CardIsOnTop();

  @override
  bool check(Pile pile, Pile? from, List<PlayCard> cards, PlayTable table) {
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
  bool check(Pile pile, Pile? from, List<PlayCard> cards, PlayTable table) {
    return switch (rankOrder) {
      RankOrder.increasing => cards.isSortedByRankIncreasingOrder,
      RankOrder.decreasing => cards.isSortedByRankDecreasingOrder,
    };
  }
}

class BuildupStartsWith extends PileCheck {
  const BuildupStartsWith({this.rank, this.suit});

  final Rank? rank;
  final Suit? suit;

  @override
  bool check(Pile pile, Pile? from, List<PlayCard> cards, PlayTable table) {
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
  bool check(Pile pile, Pile? from, List<PlayCard> cards, PlayTable table) {
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
  bool check(Pile pile, Pile? from, List<PlayCard> cards, PlayTable table) {
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
  bool check(Pile pile, Pile? from, List<PlayCard> cards, PlayTable table) {
    final cardsOnPile = table.get(pile);

    if (cardsOnPile.isEmpty || cards.isEmpty) {
      return true;
    }

    return cardsOnPile.last.suit == cards.first.suit;
  }
}

class CardsComingFrom extends PileCheck {
  const CardsComingFrom(this.originPile);

  final Pile originPile;

  @override
  bool check(Pile pile, Pile? from, List<PlayCard> cards, PlayTable table) {
    return from != null && from == originPile;
  }
}

class CardsNotComingFrom extends PileCheck {
  const CardsNotComingFrom(this.originPile);

  final Pile originPile;

  @override
  bool check(Pile pile, Pile? from, List<PlayCard> cards, PlayTable table) {
    return from != null && from != originPile;
  }
}

class PileIsEmpty extends PileCheck {
  const PileIsEmpty();

  @override
  bool check(Pile pile, Pile? from, List<PlayCard> cards, PlayTable table) {
    return table.get(pile).isEmpty;
  }
}

class PileIsNotEmpty extends PileCheck {
  const PileIsNotEmpty();

  @override
  bool check(Pile pile, Pile? from, List<PlayCard> cards, PlayTable table) {
    return table.get(pile).isNotEmpty;
  }
}

class PileOnTopIsFacingDown extends PileCheck {
  const PileOnTopIsFacingDown();

  @override
  bool check(Pile pile, Pile? from, List<PlayCard> cards, PlayTable table) {
    final cardsOnPile = table.get(pile);
    return cardsOnPile.isNotEmpty && cardsOnPile.last.isFacingDown;
  }
}
