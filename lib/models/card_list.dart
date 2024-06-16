import 'dart:math';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import 'card.dart';
import 'rank_order.dart';

typedef PlayCardList = IList<PlayCard>;

extension PlayCardListExtension on PlayCardList {
  PlayCardList get allFaceDown => PlayCardList(map((c) => c.faceDown));

  PlayCardList get allFaceUp => PlayCardList(map((c) => c.faceUp));

  PlayCardList get topmostFaceUp => isNotEmpty
      ? replace(length - 1, last.faceUp)
      : const PlayCardList.empty();

  bool isArrangedByRank(RankOrder rankOrder, {bool wrapping = false}) {
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

  PlayCardList getLast([int amount = 1]) {
    final startRange = max(length - amount, 0);
    final endRange = length;
    return sublist(startRange, endRange);
  }

  (PlayCardList, PlayCardList) splitLast([int amount = 1]) {
    final startRange = max(length - amount, 0);
    final endRange = length;
    return (sublist(0, startRange), sublist(startRange, endRange));
  }

  PlayCardList getLastFromCard(PlayCard card) {
    if (isNotEmpty && last == card) {
      return PlayCardList([card]);
    }

    final startRange = indexOf(card);
    if (startRange < 0) {
      return const PlayCardList.empty();
    }
    final endRange = length;
    return sublist(startRange, endRange);
  }

  PlayCardList getSuitStreakFromLast(RankOrder order, {bool sameSuit = false}) {
    if (length == 0) {
      return const PlayCardList.empty();
    } else if (length == 1) {
      final onlyCard = single;
      return onlyCard.isFacingUp
          ? PlayCardList([onlyCard])
          : const PlayCardList.empty();
    } else {
      int fromIndex;
      PlayCard? refCard;
      for (fromIndex = length - 1; fromIndex >= 0; fromIndex--) {
        if (refCard == null) {
          refCard = this[fromIndex];
          if (refCard.isFacingDown) {
            return const PlayCardList.empty();
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

      return sublist(fromIndex + 1, length);
    }
  }

  (PlayCardList, PlayCardList) splitLastFromCard(PlayCard card) {
    if (isNotEmpty && last == card) {
      return (const PlayCardList.empty(), PlayCardList([card]));
    }

    final startRange = indexOf(card);
    if (startRange < 0) {
      throw RangeError('Card $card is not in list $this');
    }
    final endRange = length;
    return (sublist(0, startRange), sublist(startRange, endRange));
  }

  (PlayCardList, PlayCardList) splitWhere(
    bool Function(PlayCard) test, {
    bool firstCardOnly = false,
  }) {
    bool firstCardFound = false;
    final divided = divideIn2((card) {
      if (test(card) && (!firstCardOnly || !firstCardFound)) {
        firstCardFound = true;
        return true;
      }
      return false;
    });

    return (divided.last, divided.first);
  }
}
