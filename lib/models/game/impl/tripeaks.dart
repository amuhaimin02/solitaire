import 'package:flutter/material.dart';

import '../../move_action.dart';
import '../../move_attempt.dart';
import '../../move_check.dart';
import '../../pile.dart';
import '../../pile_property.dart';
import '../solitaire.dart';

class TriPeaks extends SolitaireGame {
  TriPeaks();

  @override
  String get name => 'TriPeaks';

  @override
  String get family => 'Others';

  @override
  String get tag => 'tripeaks';

  @override
  LayoutProperty<Size> get tableSize {
    return const LayoutProperty(
      portrait: Size(10, 6),
      landscape: Size(10, 4.25), // Give gap to recycle count indicator
    );
  }

  static final _tripeaksPlacement = [
    (0, 0),
    (3, 0),
    (6, 0),
    (0, 1),
    (1, 1),
    (3, 1),
    (4, 1),
    (6, 1),
    (7, 1),
    for (int i = 0; i < 9; i++) (i, 2),
    for (int i = 0; i < 10; i++) (i, 3),
  ];

  @override
  GameSetup construct() {
    return GameSetup(
      setup: {
        for (final (x, y) in _tripeaksPlacement)
          Grid.xy(x, y): PileProperty(
            layout: PileLayout(
              region: LayoutProperty(
                portrait: Rect.fromLTWH(x * 1.0 + 1.5 - y * 0.5, y * 0.5, 1, 1),
                landscape:
                    Rect.fromLTWH(x * 1.0 + 1.5 - y * 0.5, y * 0.5, 1, 1),
              ),
              showMarker: const LayoutProperty.all(false),
            ),
            pickable: const [
              PileIsExposed(),
            ],
            placeable: const [
              NotAllowed(),
            ],
          ),
        const Stock(0): PileProperty(
          layout: const PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(4.5, 5, 1, 1),
              landscape: Rect.fromLTWH(6.5, 3, 1, 1),
            ),
            showCount: LayoutProperty.all(true),
          ),
          onStart: const [
            SetupNewDeck(count: 1),
          ],
          onSetup: [
            DistributeTo<Grid>(
              distribution: List.filled(28, 1),
            ),
            const ForAllPilesOfType<Grid>([
              FlipAllCardsFaceDown(),
              FlipExposedCardsFaceUp(),
            ])
          ],
          pickable: const [NotAllowed()],
          placeable: const [NotAllowed()],
          canTap: const [
            CanRecyclePile(willTakeFrom: Waste(0), limit: 1),
          ],
          onTap: const [
            DrawFromTop(to: Waste(0), count: 1),
          ],
        ),
        const Waste(0): PileProperty(
          layout: const PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(4.5, 3.5, 1, 1),
              landscape: Rect.fromLTWH(4.5, 3, 1, 1),
            ),
          ),
          pickable: const [
            NotAllowed(),
          ],
          placeable: const [
            CardIsSingle(),
            BuildupOneRankNearer(wrapping: true),
          ],
          afterMove: const [
            FlipExposedCardsFaceUp(),
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
      MoveAttemptTo<Waste>(),
    ];
  }
}
