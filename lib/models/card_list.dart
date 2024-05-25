import 'dart:math';

import 'package:collection/collection.dart';

import '../utils/lists.dart';
import 'card.dart';
import 'game/solitaire.dart';
import 'pile.dart';

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

  PlayCardList getLast([int amount = 1]) {
    final startRange = max(length - amount, 0);
    final endRange = length;
    return getRange(startRange, endRange).toList();
  }

  PlayCardList getUntilLast(PlayCard card) {
    if (isNotEmpty && last == card) {
      return [card];
    }

    final startRange = indexOf(card);
    if (startRange < 0) {
      throw RangeError('Card $card is not in list $this');
    }
    return getRange(startRange, length).toList();
  }

  bool followRankDecreasingOrder() {
    int? lastRank;
    for (final card in this) {
      // Ensure cards in hand follows their ranking order based on numbers (e.g. A < 2 < 3)
      if (lastRank != null) {
        return card.rank.value == lastRank - 1;
      }
      lastRank = card.rank.value;
    }
    return true;
  }

  bool get isSingle => length == 1;

  bool get isAllFacingUp => every((e) => e.isFacingUp);

  bool get isAllFacingDown => every((e) => e.isFacingDown);
}

class PlayCardGenerator {
  static PlayCardList generateOrderedDeck(
      {int numberOfDecks = 1, bool Function(PlayCard card)? criteria}) {
    return List.generate(numberOfDecks, (times) {
      final cards = <PlayCard>[];
      for (final suit in Suit.values) {
        for (final value in Rank.values) {
          final card = PlayCard(suit, value, deck: times);
          if (criteria == null || criteria(card)) {
            cards.add(card);
          }
        }
      }
      return cards;
    }).flattened.toList();
  }
}

class PlayCards {
  final Map<Pile, PlayCardList> _cards;

  const PlayCards(this._cards);

  factory PlayCards.fromGame(SolitaireGame game) {
    return PlayCards({
      for (final pile in game.piles) pile: [],
    });
  }

  PlayCardList call(Pile pile) {
    return _cards[pile] ?? [];
  }

  PlayCards copy() {
    return PlayCards({
      for (final pile in _cards.keys) pile: _cards[pile]!.copy(),
    });
  }
}
