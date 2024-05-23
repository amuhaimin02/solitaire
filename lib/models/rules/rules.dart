import 'dart:math';

import 'package:flutter/material.dart';

import '../direction.dart';
import '../pile.dart';
import '../score_tracker.dart';

abstract class SolitaireRules {
  const SolitaireRules([this._variant]);

  final SolitaireVariant<SolitaireRules>? _variant;

  SolitaireVariant<SolitaireRules> get variant {
    if (_variant == null) {
      throw ArgumentError("$name does not have any variants set");
    }
    return _variant;
  }

  bool get hasVariants => _variant != null;

  // --------------------------------------------

  String get name;

  int get drawsPerTurn;

  List<Pile> get piles;

  Layout getLayout(List<Pile> piles, [LayoutOptions? options]);

  PlayCardList prepareDrawPile(Random random);

  void setup(PlayCards cards);

  bool winConditions(PlayCards cards);

  bool canPick(PlayCardList cards, Pile from);

  bool canPlace(PlayCardList cards, Pile target, PlayCardList cardsOnTable);

  bool canAutoSolve(PlayCards cards);

  Iterable<MoveIntent> autoMoveStrategy(PlayCards cards);

  Iterable<MoveIntent> autoSolveStrategy(PlayCards cards);

  void afterEachMove(Move move, PlayCards cards, ScoreTracker score);

  Iterable<Pile> get allTableaus {
    return piles.whereType<Tableau>();
  }

  Iterable<Pile> get allFoundations {
    return piles.whereType<Foundation>();
  }
}

abstract class SolitaireVariant<T extends SolitaireRules> {
  const SolitaireVariant();
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
