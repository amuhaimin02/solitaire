import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'card.dart';
import 'direction.dart';
import 'game_state.dart';

abstract class GameRules {
  int get numberOfTableauPiles;

  int get numberOfFoundationPiles;

  TableLayout getLayout(TableLayoutOptions options);

  bool winConditions(GameState state);

  bool canPick(PlayCardList cards, CardLocation from);

  bool canPlace(
      PlayCardList cards, CardLocation target, PlayCardList cardsInPile);

  bool canAutoSolve(GameState state);

  Iterable<(PlayCard card, CardLocation from)> autoSortSteps(GameState state);
}

class Klondike extends GameRules {
  @override
  int get numberOfTableauPiles => 7;

  @override
  int get numberOfFoundationPiles => 4;

  @override
  TableLayout getLayout(TableLayoutOptions options) {
    switch (options.orientation) {
      case Orientation.portrait:
        return TableLayout(
          gridSize: const Size(7, 6),
          items: [
            for (int i = 0; i < numberOfTableauPiles; i++)
              TableauPileItem(
                region: Rect.fromLTWH(i.toDouble(), 1.3, 1, 4.7),
                stackDirection: Direction.down,
                index: i,
              ),
            DrawPileItem(
              region: const Rect.fromLTWH(6, 0, 1, 1),
            ),
            DiscardPileItem(
              region: const Rect.fromLTWH(4, 0, 2, 1),
              stackDirection: Direction.left,
              shiftStackOnPlace: true,
              numberOfCardsToShow: 3,
            ),
            for (int i = 0; i < numberOfFoundationPiles; i++)
              FoundationPileItem(
                region: Rect.fromLTWH(i.toDouble(), 0, 1, 1),
                index: i,
              ),
          ],
        );
      case Orientation.landscape:
        return TableLayout(
          gridSize: const Size(10, 4),
          items: [
            for (int i = 0; i < numberOfTableauPiles; i++)
              TableauPileItem(
                region: Rect.fromLTWH(i.toDouble() + 1.5, 0, 1, 4),
                stackDirection: Direction.down,
                index: i,
              ),
            DrawPileItem(
              region: const Rect.fromLTWH(9, 2.5, 1, 1),
            ),
            DiscardPileItem(
              region: const Rect.fromLTWH(9, 0.5, 1, 2),
              stackDirection: Direction.down,
              numberOfCardsToShow: 3,
            ),
            for (int i = 0; i < numberOfFoundationPiles; i++)
              FoundationPileItem(
                region: Rect.fromLTWH(0, i.toDouble(), 1, 1),
                index: i,
              ),
          ],
        );
    }
  }

  @override
  bool winConditions(GameState state) {
    // Easiest way to check is to ensure all cards are already in foundation pile
    return Iterable.generate(numberOfFoundationPiles,
            (f) => state.pile(Foundation(f)).length).sum ==
        PlayCard.fullSet.length;
  }

  @override
  bool canPick(PlayCardList cards, CardLocation from) {
    // Only tableau piles are allowed for picking multiple cards
    if (from is! Tableau && cards.length > 1) {
      return false;
    }

    // Cards in hand must all face up
    if (cards.any((c) => c.isFacingDown)) {
      return false;
    }

    switch (from) {
      case Tableau():
        int? lastRank;
        for (final card in cards) {
          // Ensure cards in hand follows their ranking order based on numbers (e.g. A < 2 < 3)
          if (lastRank != null) {
            return card.value.rank == lastRank - 1;
          }
          lastRank = card.value.rank;
        }
        return true;
      case _:
        // TODO: unimplemented yet
        throw UnimplementedError();
    }
  }

  @override
  bool canPlace(
      PlayCardList cards, CardLocation target, PlayCardList cardsInPile) {
    switch (target) {
      case Foundation():
        // Cannot move more than one cards all at once to foundation pile
        if (cards.length > 1) {
          return false;
        }

        final card = cards.single;

        if (cardsInPile.isEmpty) {
          return card.value == Value.ace;
        }

        final topmostCard = cardsInPile.last;

        // Cards can be stacks as long as the suit are the same and they follow rank in increasing order
        return card.isFacingUp &&
            card.suit == topmostCard.suit &&
            card.value.rank == topmostCard.value.rank + 1;

      case Tableau():
        // If column is empty, only King or card group starting with King can be placed
        if (cardsInPile.isEmpty) {
          return cards.first.value == Value.king;
        }

        final topmostCard = cardsInPile.last;

        // Card on top of each other should follow ranks in decreasing order,
        // and colors must be alternating (Diamond, Heart) <-> (Club, Spade).
        // In this case, we compare the suit "group" as they will be classified by color
        return topmostCard.isFacingUp &&
            cards.first.value.rank == topmostCard.value.rank - 1 &&
            cards.first.suit.group != topmostCard.suit.group;

      case _:
        // TODO: unimplemented yet
        throw UnimplementedError();
    }
  }

  @override
  bool canAutoSolve(GameState state) {
    if (state.pile(Draw()).isNotEmpty || state.pile(Discard()).isNotEmpty) {
      return false;
    }
    for (int i = 0; i < numberOfTableauPiles; i++) {
      final tableau = state.pile(Tableau(i));
      if (tableau.isNotEmpty && tableau.every((c) => c.isFacingDown)) {
        return false;
      }
    }
    return true;
  }

  // TODO: Improve return type
  @override
  Iterable<(PlayCard card, CardLocation from)> autoSortSteps(
      GameState state) sync* {
    for (int i = 0; i < numberOfTableauPiles; i++) {
      final tableau = state.pile(Tableau(i));
      if (tableau.isNotEmpty) {
        yield (tableau.last, Tableau(i));
      }
    }
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
    required this.type,
    required this.region,
    required this.stackDirection,
    this.showCountIndicator = false,
    this.shiftStackOnPlace = false,
    this.numberOfCardsToShow,
  });

  final CardLocation type;

  final Rect region;
  final Direction stackDirection;

  final bool showCountIndicator;

  final bool shiftStackOnPlace;

  final int? numberOfCardsToShow;
}

class DrawPileItem extends TableItem {
  DrawPileItem({
    required super.region,
  }) : super(
          type: Draw(),
          stackDirection: Direction.none,
          showCountIndicator: true,
        );
}

class DiscardPileItem extends TableItem {
  DiscardPileItem({
    required super.region,
    required super.stackDirection,
    super.shiftStackOnPlace,
    super.numberOfCardsToShow,
  }) : super(type: Discard());
}

class FoundationPileItem extends TableItem {
  FoundationPileItem({
    required super.region,
    required this.index,
  }) : super(type: Foundation(index), stackDirection: Direction.none);

  final int index;
}

class TableauPileItem extends TableItem {
  TableauPileItem({
    required super.region,
    required super.stackDirection,
    required this.index,
  }) : super(type: Tableau(index));

  final int index;
}

class TableLayoutOptions {
  TableLayoutOptions({required this.orientation, required this.mirror});
  final Orientation orientation;
  final bool mirror;
}
