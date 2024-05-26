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

class SimpleSolitaire extends SolitaireGame {
  const SimpleSolitaire();

  @override
  String get name => 'Simple';

  @override
  String get tag => name.toParamCase();

  @override
  List<Pile> get piles => [
        const Draw(),
        const Discard(),
        const Foundation(0),
        const Foundation(1),
        const Tableau(0),
        const Tableau(1),
        const Tableau(2),
        const Tableau(3),
      ];

  @override
  TableLayout getLayout(List<Pile> piles, [TableLayoutOptions? options]) {
    return TableLayout(
      gridSize: const Size(4, 3),
      items: [
        for (final pile in piles)
          switch (pile) {
            Draw() => TableLayoutItem(
                kind: const Draw(),
                region: const Rect.fromLTWH(3, 0, 1, 1),
              ),
            Discard() => TableLayoutItem(
                kind: const Discard(),
                region: const Rect.fromLTWH(2, 0, 2, 1),
              ),
            Foundation(:final index) => TableLayoutItem(
                kind: Foundation(index),
                region: Rect.fromLTWH(index.toDouble(), 0, 1, 1),
              ),
            Tableau(:final index) => TableLayoutItem(
                kind: Tableau(index),
                region: Rect.fromLTWH(index.toDouble(), 1, 1, 2),
                stackDirection: Direction.down,
              ),
          }
      ],
    );
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
  (PlayTable, int) afterEachMove(Move move, PlayTable table) {
    return (table, 1);
  }

  @override
  Iterable<MoveIntent> autoMoveStrategy(PlayTable table) {
    return [];
  }

  @override
  Iterable<MoveIntent> autoSolveStrategy(PlayTable table) {
    return [];
  }

  @override
  bool canAutoSolve(PlayTable table) {
    return false;
  }

  @override
  bool canPick(List<PlayCard> cards, Pile from) {
    return true;
  }

  @override
  bool canPlace(List<PlayCard> cards, Pile target, List<PlayCard> cardsOnPile) {
    return (target is Tableau && cards.length > 1) || cards.length == 1;
  }

  @override
  int get drawsPerTurn => 1;

  @override
  bool winConditions(PlayTable table) {
    return false;
  }
}
