import 'dart:ui';

import 'package:flutter/material.dart';

import '../../direction.dart';
import '../../move_action.dart';
import '../../move_attempt.dart';
import '../../move_check.dart';
import '../../pile.dart';
import '../../pile_property.dart';
import '../solitaire.dart';

class Golf extends SolitaireGame {
  Golf();

  @override
  String get name => 'Golf';

  @override
  String get family => 'Golf';

  @override
  String get tag => 'golf';

  @override
  LayoutProperty<Size> get tableSize {
    return const LayoutProperty(
      portrait: Size(7, 5.5),
      landscape: Size(8.5, 4),
    );
  }

  @override
  GameSetup construct() {
    return GameSetup(
      setup: {
        for (int i = 0; i < 7; i++)
          Tableau(i): PileProperty(
            layout: PileLayout(
              region: LayoutProperty(
                portrait: Rect.fromLTWH(i.toDouble(), 0, 1, 3),
                landscape: Rect.fromLTWH(i.toDouble(), 0, 1, 3),
              ),
              stackDirection: const LayoutProperty.all(Direction.down),
            ),
            pickable: const [
              CardIsSingle(),
            ],
            placeable: const [NotAllowed()],
          ),
        const Stock(0): PileProperty(
          layout: const PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(3, 4.5, 1, 1),
              landscape: Rect.fromLTWH(7.5, 2.5, 1, 1),
            ),
            showCount: LayoutProperty.all(true),
          ),
          onStart: const [
            SetupNewDeck(count: 1),
          ],
          onSetup: const [
            DistributeTo<Tableau>(
              distribution: [5, 5, 5, 5, 5, 5, 5],
              afterMove: [
                FlipAllCardsFaceUp(),
              ],
            ),
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
              portrait: Rect.fromLTWH(3, 3, 1, 1),
              landscape: Rect.fromLTWH(3, 3, 1, 1),
            ),
          ),
          pickable: const [
            NotAllowed(),
          ],
          placeable: const [
            BuildupOneRankNearer(),
          ],
        ),
      },
    );
  }

  @override
  List<MoveCheck> get objectives {
    return const [
      AllPilesOfType<Tableau>([PileIsEmpty()]),
    ];
  }

  @override
  List<MoveAttemptTo> get quickMove {
    return const [
      MoveAttemptTo<Waste>(),
    ];
  }
}
