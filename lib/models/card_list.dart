import 'dart:math';

import 'package:collection/collection.dart';

import 'card.dart';
import 'rank_order.dart';

extension PlayCardListExtension on List<PlayCard> {
  List<PlayCard> get allFaceDown => map((e) => e.faceDown).toList();

  List<PlayCard> get allFaceUp => map((e) => e.faceUp).toList();

  List<PlayCard> get topmostFaceUp =>
      mapIndexed((i, c) => i == length - 1 ? c.faceUp : c).toList();

  bool get isSortedByRankIncreasingOrder {
    int? lastRank;
    for (final card in this) {
      // Ensure cards in hand follows their ranking order based on numbers (e.g. A > 2 > 3)
      if (lastRank != null) {
        if (card.rank.value != lastRank + 1) {
          return false;
        }
      }
      lastRank = card.rank.value;
    }
    return true;
  }

  bool get isSortedByRankDecreasingOrder {
    int? lastRank;
    for (final card in this) {
      // Ensure cards in hand follows their ranking order based on numbers (e.g. A < 2 < 3)

      if (lastRank != null) {
        if (card.rank.value != lastRank - 1) {
          return false;
        }
      }
      lastRank = card.rank.value;
    }
    return true;
  }

  bool get isSingle => length == 1;

  bool get isAllFacingUp => every((e) => e.isFacingUp);

  bool get isAllFacingDown => every((e) => e.isFacingDown);

  List<PlayCard> getLast([int amount = 1]) {
    final startRange = max(length - amount, 0);
    final endRange = length;
    return slice(startRange, endRange);
  }

  (List<PlayCard>, List<PlayCard>) splitLast([int amount = 1]) {
    final startRange = max(length - amount, 0);
    final endRange = length;
    return (slice(0, startRange), slice(startRange, endRange));
  }

  List<PlayCard> getLastFromCard(PlayCard card) {
    if (isNotEmpty && last == card) {
      return [card];
    }

    final startRange = indexOf(card);
    if (startRange < 0) {
      return [];
    }
    final endRange = length;
    return slice(startRange, endRange);
  }

  List<PlayCard> getSuitStreakFromLast(RankOrder order,
      {bool sameSuit = false}) {
    if (length == 0) {
      return [];
    } else if (length == 1) {
      final onlyCard = single;
      return onlyCard.isFacingUp ? [onlyCard] : [];
    } else {
      int fromIndex;
      PlayCard? refCard;
      for (fromIndex = length - 1; fromIndex >= 0; fromIndex--) {
        if (refCard == null) {
          refCard = this[fromIndex];
          if (refCard.isFacingDown) {
            return [];
          }
        } else {
          final currentCard = this[fromIndex];
          switch (order) {
            case RankOrder.increasing:
              if (!currentCard.isOneRankUnder(refCard)) {
                break;
              }
            case RankOrder.decreasing:
              if (!currentCard.isOneRankOver(refCard)) {
                break;
              }
          }
          if (currentCard.isFacingDown) {
            break;
          }
          if (sameSuit && currentCard.suit != refCard.suit) {
            break;
          }
        }
      }

      return slice(fromIndex + 1, length);
    }
  }

  (List<PlayCard>, List<PlayCard>) splitLastFromCard(PlayCard card) {
    if (isNotEmpty && last == card) {
      return (const [], [card]);
    }

    final startRange = indexOf(card);
    if (startRange < 0) {
      throw RangeError('Card $card is not in list $this');
    }
    final endRange = length;
    return (slice(0, startRange), slice(startRange, endRange));
  }

  (List<PlayCard>, List<PlayCard>) splitWhere(bool Function(PlayCard) test) {
    final List<PlayCard> passedCards = [];
    final List<PlayCard> failedCards = [];

    for (final card in this) {
      if (test(card)) {
        passedCards.add(card);
      } else {
        failedCards.add(card);
      }
    }
    return (failedCards, passedCards);
  }
}
