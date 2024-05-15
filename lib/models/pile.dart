import 'dart:math';

import 'card.dart';

sealed class Pile {
  const Pile();
}

class Draw extends Pile {
  const Draw();

  @override
  String toString() => "Draw";
}

class Discard extends Pile {
  const Discard();
  @override
  String toString() => "Discard";
}

class Foundation extends Pile {
  final int index;

  const Foundation(this.index);

  @override
  String toString() => "Foundation($index)";
}

class Tableau extends Pile {
  final int index;

  const Tableau(this.index);

  @override
  String toString() => "Tableau($index)";
}

sealed class Action {}

class Move extends Action {
  final PlayCardList cards;
  final Pile from;
  final Pile to;

  Move(this.cards, this.from, this.to);

  @override
  String toString() => 'Move($cards, $from => $to)';
}

class GameStart extends Action {
  @override
  String toString() => 'GameStart';
}

typedef PileGetter = PlayCardList Function(Pile pile);

typedef PlayCardList = List<PlayCard>;

extension PlayCardListExtension on List<PlayCard> {
  PlayCardList get allFaceDown => map((e) => e.faceDown()).toList();

  PlayCardList get allFaceUp => map((e) => e.faceUp()).toList();

  PlayCardList pickLast([int amount = 1]) {
    final startRange = max(length - amount, 0);
    final endRange = length;
    final cardsToPick = getRange(startRange, endRange).toList();
    removeRange(startRange, endRange);
    return cardsToPick;
  }

  bool followRankDecreasingOrder() {
    int? lastRank;
    for (final card in this) {
      // Ensure cards in hand follows their ranking order based on numbers (e.g. A < 2 < 3)
      if (lastRank != null) {
        return card.value.rank == lastRank - 1;
      }
      lastRank = card.value.rank;
    }
    return true;
  }

  bool get isSingle => length == 1;

  bool get isAllFacingUp => every((e) => e.isFacingUp);

  bool get isAllFacingDown => every((e) => e.isFacingDown);
}

PlayCardList fullCardSet = [
  for (final suit in Suit.values)
    for (final value in Value.values) PlayCard(suit, value)
];

PlayCardList newShuffledDeck([Random? random]) {
  return List.from(fullCardSet)..shuffle(random);
}
