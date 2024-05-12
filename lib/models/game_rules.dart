import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'card.dart';

abstract class GameRules {
  int get numberOfTableaux;

  TableLayout getLayout(TableLayoutOptions options);

  bool winningCondition(List<PlayCardList> foundationPile);

  bool canPlaceInFoundation(
      PlayCardList cardsInHand, PlayCardList cardsOnFoundation);
  bool canPlaceInTableau(PlayCardList cardsInHand, PlayCardList cardsOnTableau);
  bool canPickFromTableau(PlayCardList cardsToPick);
}

class Klondike extends GameRules {
  @override
  int get numberOfTableaux => 7;

  @override
  TableLayout getLayout(TableLayoutOptions options) {
    switch (options.orientation) {
      case Orientation.portrait:
        return TableLayout(
          gridSize: const Size(7, 6),
          items: [
            DrawPileItem(
              placement: const Offset(6, 0),
              size: const Size(1, 1),
            ),
            DiscardPileItem(
              placement: const Offset(4, 0),
              size: const Size(2, 1),
              stackDirection: PileStackDirection.rightToLeft,
            ),
            for (int i = 0; i < 4; i++)
              FoundationPileItem(
                placement: Offset(i.toDouble(), 0),
                size: const Size(1, 1),
                index: i,
              ),
            for (int i = 0; i < 7; i++)
              TableauPileItem(
                placement: Offset(i.toDouble(), 1.3),
                size: const Size(1, 4.7),
                index: i,
                stackDirection: PileStackDirection.topDown,
              ),
          ],
        );
      case Orientation.landscape:
        return TableLayout(
          gridSize: const Size(10, 4),
          items: [
            DiscardPileItem(
              placement: const Offset(9, 0.5),
              size: const Size(1, 2),
              stackDirection: PileStackDirection.topDown,
            ),
            DrawPileItem(
              placement: const Offset(9, 2.5),
              size: const Size(1, 1),
            ),
            for (int i = 0; i < 4; i++)
              FoundationPileItem(
                placement: Offset(0, i.toDouble()),
                size: const Size(1, 1),
                index: i,
              ),
            for (int i = 0; i < 7; i++)
              TableauPileItem(
                placement: Offset(i.toDouble() + 1.5, 0),
                size: const Size(1, 4),
                stackDirection: PileStackDirection.topDown,
                index: i,
              ),
          ],
        );
    }
  }

  @override
  bool winningCondition(List<PlayCardList> foundationPile) {
    // Easiest way to check is to ensure all cards are already in foundation pile
    return foundationPile.map((pile) => pile.length).sum ==
        PlayCard.fullSet.length;
  }

  @override
  bool canPlaceInFoundation(
      PlayCardList cardsInHand, PlayCardList cardsOnFoundation) {
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
  bool canPickFromTableau(PlayCardList cardsToPick) {
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
      PlayCardList cardsInHand, PlayCardList cardsOnTableau) {
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

class TableLayout {
  final Size gridSize;
  final List<TableItem> items;

  TableLayout({
    required this.gridSize,
    required this.items,
  });
}

sealed class TableItem {
  TableItem({
    required this.placement,
    required this.size,
    this.stackDirection,
  });

  final Offset placement;
  final Size size;

  final PileStackDirection? stackDirection;
}

enum PileStackDirection { topDown, rightToLeft, zStack }

class DrawPileItem extends TableItem {
  DrawPileItem({
    required super.placement,
    required super.size,
  });
}

class DiscardPileItem extends TableItem {
  DiscardPileItem({
    required super.placement,
    required super.size,
    required super.stackDirection,
  });
}

class FoundationPileItem extends TableItem {
  FoundationPileItem({
    required super.placement,
    required super.size,
    required this.index,
  });

  final int index;
}

class TableauPileItem extends TableItem {
  TableauPileItem({
    required super.placement,
    required super.size,
    required super.stackDirection,
    required this.index,
  });

  final int index;
}

class TableLayoutOptions {
  TableLayoutOptions({required this.orientation, required this.mirror});
  final Orientation orientation;
  final bool mirror;
}
