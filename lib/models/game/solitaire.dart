import 'dart:ui';

import '../action.dart';
import '../card.dart';
import '../move_event.dart';
import '../pile.dart';
import '../move_check.dart';
import '../pile_property.dart';
import '../play_table.dart';

abstract class SolitaireGame {
  const SolitaireGame();

  String get name;

  String get family;

  String get tag;

  LayoutProperty<Size> get tableSize;

  Map<Pile, PileProperty> get piles;

  List<MoveCheck> get objectives;

  int determineScore(MoveEvent event) => 0;

  List<MoveCheck>? get canAutoSolve => null;

  Iterable<MoveIntent> quickMoveStrategy(
          Pile from, PlayCard card, PlayTable table) =>
      [];

  Iterable<MoveIntent> premoveStrategy(PlayTable table) => [];

  Iterable<MoveIntent> postMoveStrategy(PlayTable table) => [];

  Iterable<MoveIntent> autoSolveStrategy(PlayTable table) => [];

  @override
  String toString() => name;
}
