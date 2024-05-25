import 'dart:math';

import 'package:change_case/change_case.dart';
import 'package:flutter/material.dart';

import '../action.dart';
import '../card.dart';
import '../card_list.dart';
import '../direction.dart';
import '../pile.dart';
import 'solitaire.dart';

class SimpleSolitaire extends SolitaireGame {
  @override
  String get name => "Simple";

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
  Layout getLayout(List<Pile> piles, [LayoutOptions? options]) {
    return Layout(
      gridSize: const Size(4, 3),
      items: [
        for (final pile in piles)
          switch (pile) {
            Draw() => LayoutItem(
                kind: const Draw(),
                region: const Rect.fromLTWH(3, 0, 1, 1),
              ),
            Discard() => LayoutItem(
                kind: const Discard(),
                region: const Rect.fromLTWH(2, 0, 2, 1),
              ),
            Foundation(:final index) => LayoutItem(
                kind: Foundation(index),
                region: Rect.fromLTWH(index.toDouble(), 0, 1, 1),
              ),
            Tableau(:final index) => LayoutItem(
                kind: Tableau(index),
                region: Rect.fromLTWH(index.toDouble(), 1, 1, 2),
                stackDirection: Direction.down,
              ),
          }
      ],
    );
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
  (PlayCards, int) afterEachMove(Move move, PlayCards cards) {
    return (cards, 1);
  }

  @override
  Iterable<MoveIntent> autoMoveStrategy(PlayCards cards) {
    return [];
  }

  @override
  Iterable<MoveIntent> autoSolveStrategy(PlayCards cards) {
    return [];
  }

  @override
  bool canAutoSolve(PlayCards cards) {
    return false;
  }

  @override
  bool canPick(PlayCardList cards, Pile from) {
    return true;
  }

  @override
  bool canPlace(PlayCardList cards, Pile target, List<PlayCard> cardsOnTable) {
    return (target is Tableau && cards.length > 1) || cards.length == 1;
  }

  @override
  int get drawsPerTurn => 1;

  @override
  bool winConditions(PlayCards cards) {
    return false;
  }
}
