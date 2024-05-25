import 'dart:math';

import '../action.dart';
import '../card.dart';
import '../pile.dart';
import '../play_table.dart';
import '../table_layout.dart';

abstract class SolitaireGame {
  const SolitaireGame([this._variant]);

  final SolitaireVariant<SolitaireGame>? _variant;

  SolitaireVariant<SolitaireGame> get variant {
    if (_variant == null) {
      throw ArgumentError("$name does not have any variants set");
    }
    return _variant;
  }

  bool get hasVariants => _variant != null;

  // --------------------------------------------

  String get name;

  String get tag;

  int get drawsPerTurn;

  List<Pile> get piles;

  TableLayout getLayout(List<Pile> piles, [TableLayoutOptions? options]);

  List<PlayCard> prepareDrawPile(Random random);

  PlayTable setup(PlayTable table);

  bool winConditions(PlayTable table);

  bool canPick(List<PlayCard> cards, Pile from);

  bool canPlace(List<PlayCard> cards, Pile target, List<PlayCard> cardsOnPile);

  bool canAutoSolve(PlayTable table);

  Iterable<MoveIntent> autoMoveStrategy(PlayTable table);

  Iterable<MoveIntent> autoSolveStrategy(PlayTable table);

  (PlayTable card, int score) afterEachMove(Move move, PlayTable table);
}

abstract class SolitaireVariant<T extends SolitaireGame> {
  const SolitaireVariant();

  String get name;

  String get tag;
}
