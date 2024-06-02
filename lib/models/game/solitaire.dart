import '../action.dart';
import '../pile_info.dart';
import '../play_table.dart';

abstract class SolitaireGame {
  const SolitaireGame();

  String get name;

  String get family;

  String get tag;

  int get drawsPerTurn => 1;

  TableLayout get tableSize;

  List<PileItem> get piles;

  bool winConditions(PlayTable table) => false;

  bool canAutoSolve(PlayTable table) => false;

  Iterable<MoveIntent> autoMoveStrategy(PlayTable table) => [];

  Iterable<MoveIntent> autoSolveStrategy(PlayTable table) => [];

  (PlayTable card, int score) afterEachMove(Move move, PlayTable table);

  @override
  String toString() => name;
}
