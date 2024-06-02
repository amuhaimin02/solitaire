import 'dart:ui';

import '../direction.dart';
import '../pile.dart';
import '../pile_property.dart';
import 'solitaire.dart';

class SolitaireDemo extends SolitaireGame {
  @override
  String get family => 'Demo';

  @override
  String get name => 'Demo';

  @override
  String get tag => 'demo';

  @override
  TableLayout get tableSize {
    return const TableLayout(
      portrait: Size(4, 3),
      landscape: Size(4, 3),
    );
  }

  @override
  List<PileProperty> get piles {
    return [
      for (int i = 0; i < 2; i++)
        PileProperty(
          kind: Foundation(i),
          layout: PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(i.toDouble(), 0, 1, 1),
              landscape: Rect.fromLTWH(i.toDouble(), 0, 1, 1),
            ),
          ),
        ),
      for (int i = 0; i < 4; i++)
        PileProperty(
          kind: Tableau(i),
          layout: PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(i.toDouble(), 1, 1, 3),
              landscape: Rect.fromLTWH(i.toDouble(), 1, 1, 3),
            ),
            stackDirection: const LayoutProperty.all(Direction.down),
          ),
        ),
      PileProperty(
        kind: const Draw(),
        layout: const PileLayout(
          region: LayoutProperty(
            portrait: Rect.fromLTWH(3, 0, 1, 1),
            landscape: Rect.fromLTWH(3, 0, 1, 1),
          ),
        ),
      ),
      PileProperty(
        kind: const Discard(),
        layout: const PileLayout(
          region: LayoutProperty(
            portrait: Rect.fromLTWH(2, 0, 1, 1),
            landscape: Rect.fromLTWH(2, 0, 1, 1),
          ),
        ),
      ),
    ];
  }
}
