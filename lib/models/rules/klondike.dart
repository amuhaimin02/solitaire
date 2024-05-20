import 'dart:math';

import 'package:flutter/material.dart';

import '../card.dart';
import '../direction.dart';
import '../pile.dart';
import '../score_tracker.dart';
import 'rules.dart';

class Klondike extends SolitaireRules {
  static const numberOfTableauPiles = 7;

  static const numberOfFoundationPiles = 4;

  @override
  int get drawsPerTurn => 1;

  @override
  List<Pile> get piles {
    return [
      for (int i = 0; i < numberOfFoundationPiles; i++) Foundation(i),
      for (int i = 0; i < numberOfTableauPiles; i++) Tableau(i),
      const Discard(),
      const Draw(),
    ];
  }

  @override
  Layout getLayout(List<Pile> piles, [LayoutOptions? options]) {
    switch (options?.orientation) {
      case Orientation.portrait || null:
        return Layout(
          gridSize: const Size(7, 6),
          items: [
            for (final pile in piles)
              switch (pile) {
                Draw() => LayoutItem(
                    kind: const Draw(),
                    region: const Rect.fromLTWH(6, 0, 1, 1),
                    showCountIndicator: true,
                  ),
                Discard() => LayoutItem(
                    kind: const Discard(),
                    region: const Rect.fromLTWH(4, 0, 2, 1),
                    stackDirection: Direction.left,
                    shiftStackOnPlace: true,
                    numberOfCardsToShow: 3,
                  ),
                Foundation(:final index) => LayoutItem(
                    kind: Foundation(index),
                    region: Rect.fromLTWH(index.toDouble(), 0, 1, 1),
                  ),
                Tableau(:final index) => LayoutItem(
                    kind: Tableau(index),
                    region: Rect.fromLTWH(index.toDouble(), 1.3, 1, 4.7),
                    stackDirection: Direction.down,
                  ),
              }
          ],
        );
      case Orientation.landscape:
        return Layout(gridSize: const Size(10, 4), items: [
          for (final pile in piles)
            switch (pile) {
              Draw() => LayoutItem(
                  kind: const Draw(),
                  region: const Rect.fromLTWH(9, 2.5, 1, 1),
                  showCountIndicator: true,
                ),
              Discard() => LayoutItem(
                  kind: const Discard(),
                  region: const Rect.fromLTWH(9, 0.5, 1, 2),
                  stackDirection: Direction.down,
                  numberOfCardsToShow: 3,
                ),
              Foundation(:final index) => LayoutItem(
                  kind: Foundation(index),
                  region: Rect.fromLTWH(0, index.toDouble(), 1, 1),
                ),
              Tableau(:final index) => LayoutItem(
                  kind: Tableau(index),
                  region: Rect.fromLTWH(index.toDouble() + 1.5, 0, 1, 4),
                  stackDirection: Direction.down,
                ),
            }
        ]);
    }
  }

  @override
  PlayCardList prepareDrawPile(Random random) {
    return PlayCardGenerator.generateOrderedDeck()..shuffle(random);
  }

  @override
  void setup(PlayCards cards) {
    for (final t in allTableaus.cast<Tableau>()) {
      final tableau = cards(t);
      final c = cards(const Draw()).pickLast(t.index + 1);
      c.last = c.last.faceUp();

      tableau.addAll(c);
    }
  }

  @override
  bool winConditions(PlayCards cards) {
    return cards(const Draw()).isEmpty &&
        cards(const Discard()).isEmpty &&
        allTableaus.every((t) => cards(t).isEmpty);
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
  bool canPlace(PlayCardList cards, Pile target, PlayCardList cardsOnTable) {
    switch (target) {
      case Foundation():
        // Cannot move more than one cards all at once to foundation pile
        if (!cards.isSingle) {
          return false;
        }

        final card = cards.single;

        if (cardsOnTable.isEmpty) {
          return card.value == Value.ace;
        }

        final topmostCard = cardsOnTable.last;

        // Cards can be stacks as long as the suit are the same and they follow rank in increasing order
        return card.isFacingUp &&
            card.isSameSuitWith(topmostCard) &&
            card.isOneRankOver(topmostCard);

      case Tableau():
        // If column is empty, only King or card group starting with King can be placed
        if (cardsOnTable.isEmpty) {
          return cards.first.value == Value.king;
        }

        final topmostCard = cardsOnTable.last;

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
  bool canAutoSolve(PlayCards cards) {
    for (final t in allTableaus) {
      final tableau = cards(t);
      if (tableau.isNotEmpty && !tableau.isAllFacingUp) {
        return false;
      }
    }
    return true;
  }

  @override
  Iterable<MoveIntent> autoMoveStrategy(
      AutoMoveLevel level, PlayCards cards) sync* {
    for (final f in allFoundations) {
      yield MoveIntent(const Discard(), f);
    }
    for (final t in allTableaus) {
      for (final f in allFoundations) {
        yield MoveIntent(t, f);
      }
    }
  }

  @override
  Iterable<MoveIntent> autoSolveStrategy(PlayCards cards) sync* {
    // Try moving cards from tableau to foundation
    for (final t in allTableaus) {
      for (final f in allFoundations) {
        yield MoveIntent(t, f);
        final discard = cards(const Discard());
        if (discard.isNotEmpty) {
          yield MoveIntent(const Discard(), f);
          yield MoveIntent(const Discard(), t);
        }
      }
    }
    yield MoveIntent(const Draw(), const Discard());
  }

  @override
  void afterEachMove(Move move, PlayCards cards, ScoreTracker score) {
    for (final t in allTableaus) {
      final tableau = cards(t);
      if (tableau.isNotEmpty && tableau.last.isFacingDown) {
        tableau.last = tableau.last.faceUp();
      }
    }
    score.add(Random().nextInt(10));
  }
}
