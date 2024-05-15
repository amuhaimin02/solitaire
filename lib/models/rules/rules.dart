import 'dart:math';

import 'package:flutter/material.dart';

import '../direction.dart';
import '../game_state.dart';
import '../pile.dart';

abstract class Rules {
  int get numberOfTableauPiles;

  int get numberOfFoundationPiles;

  Layout getLayout(LayoutOptions options);

  PlayCardList prepareDrawPile(Random random);

  void setup(PileGetter pile);

  bool winConditions(GameState state);

  bool canPick(PlayCardList cards, Pile from);

  bool canPlace(PlayCardList cards, Pile target, PileGetter pile);

  bool canAutoSolve(PileGetter pile);

  Iterable<Move> tryAutoSolve(PileGetter pile);

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
