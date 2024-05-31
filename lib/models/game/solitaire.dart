import 'dart:math';

import '../action.dart';
import '../card.dart';
import '../pile.dart';
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

  bool canPick(List<PlayCard> cards, Pile from) => false;

  bool canPlace(
          List<PlayCard> cards, Pile target, List<PlayCard> cardsOnPile) =>
      false;

  bool canAutoSolve(PlayTable table) => false;

  Iterable<MoveIntent> autoMoveStrategy(PlayTable table) => [];

  Iterable<MoveIntent> autoSolveStrategy(PlayTable table) => [];

  (PlayTable card, int score) afterEachMove(Move move, PlayTable table);

  @override
  String toString() => name;
}
