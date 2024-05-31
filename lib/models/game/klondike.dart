import 'dart:math';

import 'package:change_case/change_case.dart';
import 'package:flutter/material.dart';

import '../../services/card_shuffler.dart';
import '../action.dart';
import '../card.dart';
import '../card_list.dart';
import '../direction.dart';
import '../pile.dart';
import '../pile_info.dart';
import '../play_table.dart';
import 'solitaire.dart';

enum KlondikeScoring {
  standard('Standard'),
  vegas('Vegas'),
  cumulativeVegas('Cumulative Vegas');

  final String fullName;

  const KlondikeScoring(this.fullName);
}

class Klondike extends SolitaireGame {
  const Klondike({required this.numberOfDraws, required this.scoring});

  @override
  String get name =>
      'Klondike ${scoring.fullName}, $numberOfDraws draw${numberOfDraws != 1 ? 's' : ''}';

  @override
  String get family => 'Klondike';

  @override
  String get tag => 'klondike-$drawsPerTurn-draw-${scoring.name.toParamCase()}';

  final int numberOfDraws;

  final KlondikeScoring scoring;

  @override
  TableLayoutNew get tableSize {
    return const TableLayoutNew(
      portrait: Size(7, 6),
      landscape: Size(10, 4),
    );
  }

  @override
  List<PileItem> get piles {
    return [
      for (int i = 0; i < 4; i++)
        PileItem(
          kind: Foundation(i),
          layout: PileLayout(
            portrait: Rect.fromLTWH(i.toDouble(), 0, 1, 1),
            landscape: Rect.fromLTWH(0, i.toDouble(), 1, 1),
          ),
        ),
      for (int i = 0; i < 7; i++)
        PileItem(
          kind: Tableau(i),
          layout: PileLayout(
            portrait: Rect.fromLTWH(i.toDouble(), 1.3, 1, 4.7),
            landscape: Rect.fromLTWH(i.toDouble() + 1.5, 0, 1, 4),
            stackDirection: Direction.down,
          ),
        ),
      PileItem(
        kind: const Draw(),
        layout: const PileLayout(
          portrait: Rect.fromLTWH(6, 0, 1, 1),
          landscape: Rect.fromLTWH(9, 2.5, 1, 1),
          showCount: true,
        ),
      ),
      PileItem(
        kind: const Discard(),
        layout: const PileLayout(
          portrait: Rect.fromLTWH(4, 0, 2, 1),
          landscape: Rect.fromLTWH(9, 0.5, 1, 2),
          portraitStackDirection: Direction.left,
          landscapeStackDirection: Direction.down,
          portraitShiftStack: true,
          previewCards: 3,
        ),
      ),
    ];
  }

  @override
  int get drawsPerTurn => numberOfDraws;

  @override
  List<PlayCard> prepareDrawPile(Random random) {
    return const CardShuffler().generateShuffledDeck(random);
  }

  @override
  PlayTable setup(PlayTable table) {
    final tableauPile = <Pile, List<PlayCard>>{};

    List<PlayCard> tableauCards;
    List<PlayCard> remainingCards = table.drawPile;

    for (final t in table.allTableauPiles) {
      (remainingCards, tableauCards) = remainingCards.splitLast(t.index + 1);
      tableauPile[t] = tableauCards.allFaceDown.topmostFaceUp;
    }

    return table.modifyMultiple({
      ...tableauPile,
      const Draw(): remainingCards.allFaceDown,
    });
  }

  @override
  bool winConditions(PlayTable table) {
    return table.drawPile.isEmpty &&
        table.discardPile.isEmpty &&
        table.allTableauPiles.every((t) => table.get(t).isEmpty);
  }

  @override
  bool canPick(List<PlayCard> cards, Pile from) {
    // Cards in hand must all face up
    if (!cards.isAllFacingUp) {
      return false;
    }

    switch (from) {
      case Tableau():
        return cards.isSortedByRankDecreasingOrder;
      case _:
        // Only tableau piles are allowed for picking multiple cards
        return cards.isSingle;
    }
  }

  @override
  bool canPlace(List<PlayCard> cards, Pile target, List<PlayCard> cardsOnPile) {
    switch (target) {
      case Foundation():
        // Cannot move more than one cards all at once to foundation pile
        if (!cards.isSingle) {
          return false;
        }

        final card = cards.single;

        if (cardsOnPile.isEmpty) {
          return card.rank == Rank.ace;
        }

        final topmostCard = cardsOnPile.last;

        // Cards can be stacks as long as the suit are the same and they follow rank in increasing order
        return card.isFacingUp &&
            card.isSameSuitWith(topmostCard) &&
            card.isOneRankOver(topmostCard);

      case Tableau():
        // If column is empty, only King or card group starting with King can be placed
        if (cardsOnPile.isEmpty) {
          return cards.first.rank == Rank.king;
        }

        final topmostCard = cardsOnPile.last;

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
  bool canAutoSolve(PlayTable table) {
    for (final t in table.allTableauPiles) {
      final tableau = table.get(t);
      if (tableau.isNotEmpty && !tableau.isAllFacingUp) {
        return false;
      }
    }
    return true;
  }

  @override
  Iterable<MoveIntent> autoMoveStrategy(PlayTable table) sync* {
    for (final f in table.allFoundationPiles) {
      yield MoveIntent(const Discard(), f);
    }
    for (final t in table.allTableauPiles) {
      for (final f in table.allFoundationPiles) {
        yield MoveIntent(t, f);
      }
    }
  }

  @override
  Iterable<MoveIntent> autoSolveStrategy(PlayTable table) sync* {
    // Try moving cards from tableau to foundation
    for (final t in table.allTableauPiles) {
      for (final f in table.allFoundationPiles) {
        yield MoveIntent(t, f);
        final discard = table.discardPile;
        if (discard.isNotEmpty) {
          yield MoveIntent(const Discard(), f);
          yield MoveIntent(const Discard(), t);
        }
      }
    }
    yield const MoveIntent(Draw(), Discard());
  }

  @override
  (PlayTable, int) afterEachMove(Move move, PlayTable table) {
    for (final t in table.allTableauPiles) {
      final tableau = table.get(t);
      if (tableau.isNotEmpty && tableau.last.isFacingDown) {
        table = table.modify(t, tableau.topmostFaceUp);
      }
    }

    return (table, 5);
  }
}
