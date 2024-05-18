import 'dart:math';

import 'package:flutter/material.dart';

import '../direction.dart';
import '../pile.dart';

abstract class SolitaireRules {
  int get numberOfTableauPiles;

  int get numberOfFoundationPiles;

  int get drawsPerTurn;

  Layout getLayout([LayoutOptions? options]);

  PlayCardList prepareDrawPile(Random random);

  void setup(PlayCards cards);

  bool winConditions(PlayCards cards);

  bool canPick(PlayCardList cards, Pile from);

  bool canPlace(PlayCardList cards, Pile target, PlayCardList cardsOnTable);

  bool canAutoSolve(PlayCards cards);

  Iterable<MoveIntent> autoMoveStrategy(AutoMoveLevel level, PlayCards cards);

  Iterable<MoveIntent> autoSolveStrategy(PlayCards cards);

  int determineScoreForMove(int currentScore, Move move);

  Iterable<Pile> get allTableaus {
    return Iterable.generate(numberOfTableauPiles, (i) => Tableau(i));
  }

  Iterable<Pile> get allFoundations {
    return Iterable.generate(numberOfFoundationPiles, (i) => Foundation(i));
  }
}

class Layout {
  final Size gridSize;
  final List<LayoutItem> items;

  Layout({
    required this.gridSize,
    required this.items,
  });
}

class LayoutItem {
  LayoutItem({
    required this.kind,
    required this.region,
    this.stackDirection = Direction.none,
    this.showCountIndicator = false,
    this.shiftStackOnPlace = false,
    this.numberOfCardsToShow,
  });

  final Pile kind;

  final Rect region;
  final Direction stackDirection;

  final bool showCountIndicator;

  final bool shiftStackOnPlace;

  final int? numberOfCardsToShow;
}

class LayoutOptions {
  LayoutOptions({required this.orientation, required this.mirror});
  final Orientation orientation;
  final bool mirror;
}
