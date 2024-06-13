import 'package:flutter/material.dart';

import '../../../utils/types.dart';
import '../../move_action.dart';
import '../../move_attempt.dart';
import '../../move_check.dart';
import '../../pile.dart';
import '../../pile_property.dart';
import '../solitaire.dart';

class Pyramid extends SolitaireGame {
  Pyramid();

  @override
  String get name => 'Pyramid';

  @override
  String get family => 'Pyramid';

  @override
  String get tag => 'pyramid';

  @override
  LayoutProperty<Size> get tableSize {
    return const LayoutProperty(
      portrait: Size(7, 6),
      landscape: Size(9, 4),
    );
  }

  @override
  GameSetup construct() {
    return GameSetup(
      setup: {
        for (int y = 0; y < 7; y++)
          for (int x = 0; x <= y; x++)
            Grid(x, y): PileProperty(
              layout: PileLayout(
                region: LayoutProperty(
                  portrait: Rect.fromLTWH(x * 1.0 + 3 - y * 0.5, y * 0.5, 1, 1),
                  landscape:
                      Rect.fromLTWH(x * 1.0 + 3 - y * 0.5, y * 0.5, 1, 1),
                ),
                showMarker: const LayoutProperty.all(false),
              ),
              pickable: const [
                PileIsExposed(),
              ],
              placeable: const [
                PileIsExposed(),
                BuildupRankValueAddUpTo(13),
              ],
            ),
        const Foundation(0): PileProperty(
          layout: const PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(1, 5, 1, 1),
              landscape: Rect.fromLTWH(8, 0, 1, 1),
            ),
          ),
          pickable: const [
            CardIsOnTop(),
          ],
          placeable: const [
            CardsRankValueAddUpTo(13),
          ],
          afterMove: const [
            FlipAllCardsFaceDown(),
          ],
        ),
        const Stock(0): PileProperty(
          layout: const PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(5, 5, 1, 1),
              landscape: Rect.fromLTWH(8, 3, 1, 1),
            ),
            showCount: LayoutProperty.all(true),
          ),
          onStart: const [
            SetupNewDeck(count: 1),
            FlipAllCardsFaceDown(),
          ],
          onSetup: [
            DistributeTo<Grid>(
              distribution: List.filled(28, 1),
            ),
            const FlipAllCardsFaceUp(),
          ],
          canTap: const [
            CanRecyclePile(
              limit: intMaxValue,
              willTakeFrom: Waste(0),
            ),
          ],
          onTap: const [
            If(
              condition: [PileIsEmpty()],
              ifTrue: [RecyclePile(takeFrom: Waste(0), faceUp: true)],
              ifFalse: [DrawFromTop(to: Waste(0), count: 1)],
            ),
          ],
          pickable: const [
            CardIsOnTop(),
          ],
          placeable: const [NotAllowed()],
        ),
        const Waste(0): PileProperty(
          layout: const PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(3, 5, 1, 1),
              landscape: Rect.fromLTWH(8, 1.5, 1, 1),
            ),
          ),
          pickable: const [
            CardIsOnTop(),
          ],
          placeable: const [
            // NotAllowed(),
          ],
        ),
      },
    );
  }

  @override
  List<MoveCheck> get objectives {
    return const [
      AllPilesOfType<Grid>([PileIsEmpty()]),
    ];
  }

  @override
  List<MoveAttemptTo> get quickMove {
    return const [
      MoveAttemptTo<Grid>(),
      MoveAttemptTo<Foundation>(),
    ];
  }

  @override
  List<MoveAttempt> get postMove {
    return const [
      MoveCompletedPairs<Grid, Foundation>(),
    ];
  }
}
