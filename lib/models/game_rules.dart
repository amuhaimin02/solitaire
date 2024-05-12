import 'package:collection/collection.dart';

import 'card.dart';

abstract class GameRules {
  bool winningCondition(List<PlayCardStack> foundationPile);

  bool canPlaceInFoundation(
      PlayCardStack cardsInHand, PlayCardStack cardsOnFoundation);
  bool canPlaceInTableau(
      PlayCardStack cardsInHand, PlayCardStack cardsOnTableau);
  bool canPickFromTableau(PlayCardStack cardsToPick);
}

class Klondike extends GameRules {
  @override
  bool winningCondition(List<PlayCardStack> foundationPile) {
    // Easiest way to check is to ensure all cards are already in foundation pile
    return foundationPile.map((pile) => pile.length).sum ==
        PlayCard.fullSet.length;
  }

  @override
  bool canPlaceInFoundation(
      PlayCardStack cardsInHand, PlayCardStack cardsOnFoundation) {
    if (cardsInHand.length > 1) {
      // Cannot move more than one cards all at once to foundation pile
      return false;
    }

    final pickedCard = cardsInHand.single;

    // If pile is empty, only aces can be placed
    if (cardsOnFoundation.isEmpty) {
      return pickedCard.value == Value.ace;
    }

    final topmostCard = cardsOnFoundation.last;

    // Cards can be stacks as long as the suit are the same and they follow rank in increasing order
    return pickedCard.isFacingUp &&
        pickedCard.suit == topmostCard.suit &&
        pickedCard.value.rank == topmostCard.value.rank + 1;
  }

  @override
  bool canPickFromTableau(PlayCardStack cardsToPick) {
    // One card pick is always acceptable as long as it is facing up
    if (cardsToPick.length == 1) {
      return cardsToPick.single.isFacingUp;
    }

    int? lastRank;
    for (final card in cardsToPick) {
      // The cards in group should all be facing up
      if (card.isFacingDown) {
        return false;
      }

      // Ensure card in group follows their ranking order based on numbers (e.g. A < 2 < 3)
      if (lastRank != null) {
        return card.value.rank == lastRank - 1;
      }
      lastRank = card.value.rank;
    }
    return true;
  }

  @override
  bool canPlaceInTableau(
      PlayCardStack cardsInHand, PlayCardStack cardsOnTableau) {
    // If column is empty, only King or card group starting with King can be placed
    if (cardsOnTableau.isEmpty) {
      return cardsInHand.first.value == Value.king;
    }

    final topmostCard = cardsOnTableau.last;

    // Card on top of each other should follow ranks in decreasing order,
    // and colors must be alternating (Diamond, Heart) <-> (Club, Spade).
    // In this case, we compare the suit "group" as they will be classified by color
    return topmostCard.isFacingUp &&
        cardsInHand.first.value.rank == topmostCard.value.rank - 1 &&
        cardsInHand.first.suit.group != topmostCard.suit.group;
  }
}
