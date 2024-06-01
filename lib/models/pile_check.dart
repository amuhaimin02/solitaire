import 'card.dart';
import 'card_list.dart';
import 'pile.dart';
import 'play_table.dart';

enum RankOrder { increasing, decreasing }

abstract class PileCheck {
  const PileCheck();

  bool check(Pile pile, List<PlayCard> cardsInHand, PlayTable table);

  static bool checkAll(List<PileCheck>? checks, Pile pile,
      List<PlayCard> cardsInHand, PlayTable table) {
    return checks?.every((item) => item.check(pile, cardsInHand, table)) ==
        true;
  }
}

class CardsAreFacingUp extends PileCheck {
  const CardsAreFacingUp();

  @override
  bool check(Pile pile, List<PlayCard> cardsInHand, PlayTable table) {
    return cardsInHand.isAllFacingUp;
  }
}

class CardIsOnTop extends PileCheck {
  const CardIsOnTop();

  @override
  bool check(Pile pile, List<PlayCard> cardsInHand, PlayTable table) {
    final cardsOnPile = table.get(pile);

    return cardsInHand.isSingle &&
        cardsOnPile.isNotEmpty &&
        cardsOnPile.last == cardsInHand.single;
  }
}

class CardsFollowRankOrder extends PileCheck {
  const CardsFollowRankOrder(this.rankOrder);

  final RankOrder rankOrder;

  @override
  bool check(Pile pile, List<PlayCard> cardsInHand, PlayTable table) {
    return switch (rankOrder) {
      RankOrder.increasing => cardsInHand.isSortedByRankIncreasingOrder,
      RankOrder.decreasing => cardsInHand.isSortedByRankDecreasingOrder,
    };
  }
}

class BuildupStartsWith extends PileCheck {
  const BuildupStartsWith({this.rank, this.suit});

  final Rank? rank;
  final Suit? suit;

  @override
  bool check(Pile pile, List<PlayCard> cardsInHand, PlayTable table) {
    final cardsOnPile = table.get(pile);

    if (cardsOnPile.isNotEmpty) {
      return true;
    }

    final firstCardInHand = cardsInHand.first;
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
  bool check(Pile pile, List<PlayCard> cardsInHand, PlayTable table) {
    final cardsOnPile = table.get(pile);

    if (cardsOnPile.isEmpty) {
      return true;
    }

    return switch (rankOrder) {
      RankOrder.increasing =>
        cardsOnPile.last.isOneRankUnder(cardsInHand.first),
      RankOrder.decreasing => cardsOnPile.last.isOneRankOver(cardsInHand.first),
    };
  }
}

class BuildupAlternateColors extends PileCheck {
  const BuildupAlternateColors();

  @override
  bool check(Pile pile, List<PlayCard> cardsInHand, PlayTable table) {
    final cardsOnPile = table.get(pile);

    if (cardsOnPile.isEmpty) {
      return true;
    }

    return !cardsOnPile.last.isSameColor(cardsInHand.first);
  }
}

class BuildupSameSuit extends PileCheck {
  const BuildupSameSuit();

  @override
  bool check(Pile pile, List<PlayCard> cardsInHand, PlayTable table) {
    final cardsOnPile = table.get(pile);

    if (cardsOnPile.isEmpty) {
      return true;
    }

    return cardsOnPile.last.suit == cardsInHand.first.suit;
  }
}
