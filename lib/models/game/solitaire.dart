import 'dart:ui';

import '../action.dart';
import '../card.dart';
import '../pile.dart';
import '../pile_property.dart';
import '../play_table.dart';

abstract class SolitaireGame {
  const SolitaireGame();

  String get name;

  String get family;

  String get tag;

  LayoutProperty<Size> get tableSize;

  Map<Pile, PileProperty> get piles;

  bool winConditions(PlayTable table) => false;

  bool canAutoSolve(PlayTable table) => false;

  Iterable<MoveIntent> quickMoveStrategy(
          Pile from, PlayCard card, PlayTable table) =>
      [];

  Iterable<MoveIntent> premoveStrategy(PlayTable table) => [];

  Iterable<MoveIntent> autoSolveStrategy(PlayTable table) => [];

  @override
  String toString() => name;
}
