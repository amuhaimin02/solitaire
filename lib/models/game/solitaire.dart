import 'dart:math';

import '../action.dart';
import '../card.dart';
import '../pile.dart';
import '../play_table.dart';
import '../table_layout.dart';

abstract class SolitaireGame {
  const SolitaireGame();

  String get name;

  String get family;

  String get tag;

  int get drawsPerTurn;

  TableLayout getLayout([TableLayoutOptions? options]);

  List<PlayCard> prepareDrawPile(Random random);

  PlayTable setup(PlayTable table);

  bool winConditions(PlayTable table);

  bool canPick(List<PlayCard> cards, Pile from);

  bool canPlace(List<PlayCard> cards, Pile target, List<PlayCard> cardsOnPile);

  bool canAutoSolve(PlayTable table);

  Iterable<MoveIntent> autoMoveStrategy(PlayTable table);

  Iterable<MoveIntent> autoSolveStrategy(PlayTable table);

  (PlayTable card, int score) afterEachMove(Move move, PlayTable table);

  @override
  String toString() => name;

  PlayTable generateRandomSetup() {
    // TODO: Do not use predetermined random
    final table = PlayTable.fromGame(this)
        .modify(const Draw(), prepareDrawPile(Random(1)));
    return setup(table);
  }
}
