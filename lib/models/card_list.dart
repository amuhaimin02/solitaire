import 'dart:math';

import 'package:collection/collection.dart';

import 'card.dart';

extension PlayCardListExtension on List<PlayCard> {
  List<PlayCard> get allFaceDown => map((e) => e.faceDown()).toList();

  List<PlayCard> get allFaceUp => map((e) => e.faceUp()).toList();

  List<PlayCard> get topmostFaceUp =>
      mapIndexed((i, c) => i == length - 1 ? c.faceUp() : c).toList();

  bool get isSortedByRankIncreasingOrder {
    int? lastRank;
    for (final card in this) {
      // Ensure cards in hand follows their ranking order based on numbers (e.g. A > 2 > 3)
      if (lastRank != null) {
        return card.rank.value == lastRank + 1;
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
        return card.rank.value == lastRank - 1;
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
      throw RangeError('Card $card is not in list $this');
    }
    final endRange = length;
    return slice(startRange, endRange);
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
}
