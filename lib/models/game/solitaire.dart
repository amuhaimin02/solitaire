import '../action.dart';
import '../pile_property.dart';
import '../play_table.dart';

abstract class SolitaireGame {
  const SolitaireGame();

  String get name;

  String get family;

  String get tag;

  TableLayout get tableSize;

  List<PileProperty> get piles;

  bool winConditions(PlayTable table) => false;

  bool canAutoSolve(PlayTable table) => false;

  Iterable<MoveIntent> autoMoveStrategy(PlayTable table) => [];

  Iterable<MoveIntent> autoSolveStrategy(PlayTable table) => [];

  @override
  String toString() => name;
}
