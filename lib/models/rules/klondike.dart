import 'dart:math';

import 'package:flutter/material.dart';

import '../card.dart';
import '../direction.dart';
import '../pile.dart';
import 'rules.dart';

class Klondike extends SolitaireRules {
  @override
  int get numberOfTableauPiles => 7;

  @override
  int get numberOfFoundationPiles => 4;

  @override
  int get drawsPerTurn => 1;

  @override
  Layout getLayout(LayoutOptions options) {
    switch (options.orientation) {
      case Orientation.portrait:
        return Layout(
          gridSize: const Size(7, 6),
          items: [
            for (int i = 0; i < numberOfTableauPiles; i++)
              LayoutItem(
                kind: Tableau(i),
                region: Rect.fromLTWH(i.toDouble(), 1.3, 1, 4.7),
                stackDirection: Direction.down,
              ),
            LayoutItem(
              kind: const Discard(),
              region: const Rect.fromLTWH(4, 0, 2, 1),
              stackDirection: Direction.left,
              shiftStackOnPlace: true,
              numberOfCardsToShow: 3,
            ),
            for (int i = 0; i < numberOfFoundationPiles; i++)
              LayoutItem(
                kind: Foundation(i),
                region: Rect.fromLTWH(i.toDouble(), 0, 1, 1),
              ),
            LayoutItem(
              kind: const Draw(),
              region: const Rect.fromLTWH(6, 0, 1, 1),
              showCountIndicator: true,
            ),
          ],
        );
      case Orientation.landscape:
        return Layout(
          gridSize: const Size(10, 4),
          items: [
            for (int i = 0; i < numberOfTableauPiles; i++)
              LayoutItem(
                kind: Tableau(i),
                region: Rect.fromLTWH(i.toDouble() + 1.5, 0, 1, 4),
                stackDirection: Direction.down,
              ),
            for (int i = 0; i < numberOfFoundationPiles; i++)
              LayoutItem(
                kind: Foundation(i),
                region: Rect.fromLTWH(0, i.toDouble(), 1, 1),
              ),
            LayoutItem(
              kind: const Discard(),
              region: const Rect.fromLTWH(9, 0.5, 1, 2),
              stackDirection: Direction.down,
              numberOfCardsToShow: 3,
            ),
            LayoutItem(
              kind: const Draw(),
              region: const Rect.fromLTWH(9, 2.5, 1, 1),
              showCountIndicator: true,
            ),
          ],
        );
    }
  }

  @override
  PlayCardList prepareDrawPile(Random random) {
    return PlayCardGenerator.generateOrderedDeck()..shuffle(random);
  }

  @override
  void setup(PileGetter pile) {
    for (final t in allTableaus.cast<Tableau>()) {
      final tableau = pile(t);
      final cards = pile(const Draw()).pickLast(t.index + 1);
      cards.last = cards.last.faceUp();

      tableau.addAll(cards);
    }
  }

  @override
  bool winConditions(PileGetter pile) {
    return pile(const Draw()).isEmpty &&
        pile(const Discard()).isEmpty &&
        allTableaus.every((t) => pile(t).isEmpty);
    // Easiest way to check is to ensure all cards are already in foundation pile
    // return Iterable.generate(numberOfFoundationPiles,
    //         (f) => state.pile(Foundation(f)).length).sum ==
    //     PlayCard.numberOfCardsInDeck;
  }

  @override
  bool canPick(PlayCardList cards, Pile from) {
    // Cards in hand must all face up
    if (!cards.isAllFacingUp) {
      return false;
    }

    switch (from) {
      case Tableau():
        return cards.followRankDecreasingOrder();
      case _:
        // Only tableau piles are allowed for picking multiple cards
        return cards.isSingle;
    }
  }

  @override
  bool canPlace(PlayCardList cards, Pile target, PileGetter pile) {
    final cardsInPile = pile(target);

    switch (target) {
      case Foundation():
        // Cannot move more than one cards all at once to foundation pile
        if (!cards.isSingle) {
          return false;
        }

        final card = cards.single;

        if (cardsInPile.isEmpty) {
          return card.value == Value.ace;
        }

        final topmostCard = cardsInPile.last;

        // Cards can be stacks as long as the suit are the same and they follow rank in increasing order
        return card.isFacingUp &&
            card.isSameSuitWith(topmostCard) &&
            card.isOneRankOver(topmostCard);

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
            cards.first.isOneRankUnder(topmostCard) &&
            !cards.first.isSameColor(topmostCard);

      case Draw() || Discard():
        // Cannot return card back to these piles
        return false;
    }
  }

  @override
  bool canAutoSolve(PileGetter pile) {
    for (final t in allTableaus) {
      final tableau = pile(t);
      if (tableau.isNotEmpty && !tableau.isAllFacingUp) {
        return false;
      }
    }
    return true;
  }

  @override
  Iterable<MoveIntent> tryAutoSolve(PileGetter pile) sync* {
    // Try moving cards from tableau to foundation
    for (final t in allTableaus) {
      for (final f in allFoundations) {
        final tableau = pile(t);
        if (tableau.isNotEmpty) {
          yield MoveIntent(t, f);
        }
        final discard = pile(const Discard());
        if (discard.isNotEmpty) {
          yield MoveIntent(const Discard(), t);
          yield MoveIntent(const Discard(), f);
        }
      }
    }
    yield MoveIntent(const Draw(), const Discard());
  }

  @override
  int determineScoreForMove(int currentScore, Move move) {
    return currentScore + 5;
  }
}
