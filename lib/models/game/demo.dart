import 'dart:math';
import 'dart:ui';

import '../action.dart';
import '../card.dart';
import '../direction.dart';
import '../pile.dart';
import '../pile_info.dart';
import '../play_table.dart';
import 'solitaire.dart';

class SolitaireDemo extends SolitaireGame {
  @override
  String get family => 'Demo';

  @override
  String get name => 'Demo';

  @override
  String get tag => 'demo';

  @override
  List<PileItem> get piles {
    return [
      for (int i = 0; i < 2; i++)
        PileItem(
          kind: Foundation(i),
          layout: PileLayout(
            portrait: Rect.fromLTWH(i.toDouble(), 0, 1, 1),
            landscape: Rect.fromLTWH(i.toDouble(), 0, 1, 1),
          ),
        ),
      for (int i = 0; i < 4; i++)
        PileItem(
          kind: Tableau(i),
          layout: PileLayout(
            portrait: Rect.fromLTWH(i.toDouble(), 1, 1, 3),
            landscape: Rect.fromLTWH(i.toDouble(), 1, 1, 3),
            stackDirection: Direction.down,
          ),
        ),
      PileItem(
        kind: const Draw(),
        layout: const PileLayout(
          portrait: Rect.fromLTWH(3, 0, 1, 1),
          landscape: Rect.fromLTWH(3, 0, 1, 1),
        ),
      ),
      PileItem(
        kind: const Discard(),
        layout: const PileLayout(
          portrait: Rect.fromLTWH(2, 0, 1, 1),
          landscape: Rect.fromLTWH(2, 0, 1, 1),
        ),
      ),
    ];
  }

  @override
  List<PlayCard> prepareDrawPile(Random random) {
    throw UnimplementedError();
  }

  @override
  PlayTable setup(PlayTable table) {
    throw UnimplementedError();
  }

  @override
  TableLayoutNew get tableSize {
    return const TableLayoutNew(
      portrait: Size(4, 4),
      landscape: Size(4, 4),
    );
  }

  @override
  (PlayTable, int) afterEachMove(Move move, PlayTable table) {
    // TODO: implement afterEachMove
    throw UnimplementedError();
  }
}
