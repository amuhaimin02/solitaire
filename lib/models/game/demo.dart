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
  LayoutProperty<Size> get tableSize {
    return const LayoutProperty(
      portrait: Size(4, 3),
      landscape: Size(4, 3),
    );
  }

  @override
  Map<Pile, PileProperty> get piles {
    return {
      for (int i = 0; i < 2; i++)
        Foundation(i): PileProperty(
          layout: PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(i.toDouble(), 0, 1, 1),
              landscape: Rect.fromLTWH(i.toDouble(), 0, 1, 1),
            ),
          ),
        ),
      for (int i = 0; i < 4; i++)
        Tableau(i): PileProperty(
          layout: PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(i.toDouble(), 1, 1, 3),
              landscape: Rect.fromLTWH(i.toDouble(), 1, 1, 3),
            ),
            stackDirection: const LayoutProperty.all(Direction.down),
          ),
        ),
      const Draw(): PileProperty(
        layout: const PileLayout(
          region: LayoutProperty(
            portrait: Rect.fromLTWH(3, 0, 1, 1),
            landscape: Rect.fromLTWH(3, 0, 1, 1),
          ),
        ),
      ),
      const Discard(): PileProperty(
        layout: const PileLayout(
          region: LayoutProperty(
            portrait: Rect.fromLTWH(2, 0, 1, 1),
            landscape: Rect.fromLTWH(2, 0, 1, 1),
          ),
        ),
      ),
    };
  }
}
