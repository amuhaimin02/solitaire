import 'dart:math';

import 'package:change_case/change_case.dart';
import 'package:flutter/material.dart';

import '../../services/card_shuffler.dart';
import '../action.dart';
import '../card.dart';
import '../card_list.dart';
import '../direction.dart';
import '../pile.dart';
import '../play_table.dart';
import '../table_layout.dart';
import 'solitaire.dart';

class Klondike extends SolitaireGame {
  const Klondike(KlondikeVariant super.variant);

  @override
  String get name => 'Klondike';

  @override
  String get tag => 'klondike';

  static const numberOfTableauPiles = 7;

  static const numberOfFoundationPiles = 4;

  @override
  int get drawsPerTurn {
    return switch ((variant as KlondikeVariant).draws) {
      KlondikeDraws.oneDraw => 1,
      KlondikeDraws.threeDraws => 3,
    };
  }

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
  TableLayout getLayout(List<Pile> piles, [TableLayoutOptions? options]) {
    switch (options?.orientation) {
      case Orientation.portrait || null:
        return TableLayout(
          gridSize: const Size(7, 6),
          items: [
            for (final pile in piles)
              switch (pile) {
                Draw() => TableLayoutItem(
                    kind: const Draw(),
                    region: const Rect.fromLTWH(6, 0, 1, 1),
                    showCountIndicator: true,
                  ),
                Discard() => TableLayoutItem(
                    kind: const Discard(),
                    region: const Rect.fromLTWH(4, 0, 2, 1),
                    stackDirection: Direction.left,
                    shiftStackOnPlace: true,
                    numberOfCardsToShow: 3,
                  ),
                Foundation(:final index) => TableLayoutItem(
                    kind: Foundation(index),
                    region: Rect.fromLTWH(index.toDouble(), 0, 1, 1),
                  ),
                Tableau(:final index) => TableLayoutItem(
                    kind: Tableau(index),
                    region: Rect.fromLTWH(index.toDouble(), 1.3, 1, 4.7),
                    stackDirection: Direction.down,
                  ),
              }
          ],
        );
      case Orientation.landscape:
        return TableLayout(gridSize: const Size(10, 4), items: [
          for (final pile in piles)
            switch (pile) {
              Draw() => TableLayoutItem(
                  kind: const Draw(),
                  region: const Rect.fromLTWH(9, 2.5, 1, 1),
                  showCountIndicator: true,
                ),
              Discard() => TableLayoutItem(
                  kind: const Discard(),
                  region: const Rect.fromLTWH(9, 0.5, 1, 2),
                  stackDirection: Direction.down,
                  numberOfCardsToShow: 3,
                ),
              Foundation(:final index) => TableLayoutItem(
                  kind: Foundation(index),
                  region: Rect.fromLTWH(0, index.toDouble(), 1, 1),
                ),
              Tableau(:final index) => TableLayoutItem(
                  kind: Tableau(index),
                  region: Rect.fromLTWH(index.toDouble() + 1.5, 0, 1, 4),
                  stackDirection: Direction.down,
                ),
            }
        ]);
    }
  }

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
    yield MoveIntent(const Draw(), const Discard());
  }

  @override
  (PlayTable, int) afterEachMove(Move move, PlayTable table) {
    PlayTable updatedTable = table;

    for (final t in table.allTableauPiles) {
      final tableau = table.get(t);
      if (tableau.isNotEmpty && tableau.last.isFacingDown) {
        table.modify(t, tableau.topmostFaceUp);
      }
    }

    return (updatedTable, 5);
  }
}

class KlondikeVariant extends SolitaireVariant<Klondike> {
  final KlondikeDraws draws;

  final KlondikeScoring scoring;

  const KlondikeVariant({
    required this.draws,
    required this.scoring,
  });

  @override
  String get name => '${scoring.fullName}, ${draws.fullName}';

  @override
  String get tag => '${scoring.name.toParamCase()}-${draws.name.toParamCase()}';

  int calculateScore(Move move, PlayTable table) {
    switch (scoring) {
      case KlondikeScoring.standard:
        return 1;
      case KlondikeScoring.vegas:
        return 5;
      case KlondikeScoring.cumulativeVegas:
        return 10;
    }
  }
}

enum KlondikeDraws {
  oneDraw('1 draw'),
  threeDraws('3 draws');

  final String fullName;

  const KlondikeDraws(this.fullName);
}

enum KlondikeScoring {
  standard('Standard'),
  vegas('Vegas'),
  cumulativeVegas('Cumulative Vegas');

  final String fullName;

  const KlondikeScoring(this.fullName);
}
