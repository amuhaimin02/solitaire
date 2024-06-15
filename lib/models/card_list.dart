import 'dart:math';

import 'package:collection/collection.dart';

import 'card.dart';
import 'rank_order.dart';

extension PlayCardListExtension on List<PlayCard> {
  List<PlayCard> get allFaceDown => map((e) => e.faceDown).toList();

  List<PlayCard> get allFaceUp => map((e) => e.faceUp).toList();

  List<PlayCard> get topmostFaceUp =>
      mapIndexed((i, c) => i == length - 1 ? c.faceUp : c).toList();

  bool isSortedByRank(RankOrder rankOrder, {bool wrapping = false}) {
    if (length <= 1) {
      return true;
    }
    final gap = switch (rankOrder) {
      RankOrder.increasing => 1,
      RankOrder.decreasing => -1
    };

    for (int i = 1; i < length; i++) {
      if (this[i].rank != this[i - 1].rank.next(wrapping: wrapping, gap: gap)) {
        return false;
      }
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

  (List<PlayCard>, List<PlayCard>) splitWhere(
    bool Function(PlayCard) test, {
    bool firstCardOnly = false,
  }) {
    final List<PlayCard> passedCards = [];
    final List<PlayCard> failedCards = [];

    for (final card in this) {
      if (test(card) && (!firstCardOnly || passedCards.isEmpty)) {
        passedCards.add(card);
      } else {
        failedCards.add(card);
      }
    }
    return (failedCards, passedCards);
  }
}
