import 'dart:ui';

import '../../direction.dart';
import '../../move_action.dart';
import '../../move_check.dart';
import '../../pile.dart';
import '../../pile_property.dart';
import '../solitaire.dart';

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
          pickable: const [NotAllowed()],
          placeable: const [NotAllowed()],
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
          pickable: const [NotAllowed()],
          placeable: const [NotAllowed()],
        ),
      const Stock(0): PileProperty(
        layout: const PileLayout(
          region: LayoutProperty(
            portrait: Rect.fromLTWH(3, 0, 1, 1),
            landscape: Rect.fromLTWH(3, 0, 1, 1),
          ),
        ),
        onStart: const [
          SetupNewDeck(count: 1),
          FlipAllCardsFaceDown(),
        ],
        onSetup: const [
          DistributeTo<Tableau>(
            distribution: [1, 2, 3, 4],
            afterMove: [
              FlipAllCardsFaceDown(),
              FlipTopCardFaceUp(),
            ],
          )
        ],
        pickable: const [NotAllowed()],
        placeable: const [NotAllowed()],
      ),
      const Waste(0): PileProperty(
        layout: const PileLayout(
          region: LayoutProperty(
            portrait: Rect.fromLTWH(2, 0, 1, 1),
            landscape: Rect.fromLTWH(2, 0, 1, 1),
          ),
        ),
        pickable: const [NotAllowed()],
        placeable: const [NotAllowed()],
      ),
    };
  }

  @override
  List<MoveCheck> get objectives => [];
}
