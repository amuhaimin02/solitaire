import 'dart:ui';

import 'package:flutter/material.dart';

import '../../card.dart';
import '../../direction.dart';
import '../../move_action.dart';
import '../../move_attempt.dart';
import '../../move_check.dart';
import '../../pile.dart';
import '../../pile_property.dart';
import '../solitaire.dart';

class Maze extends SolitaireGame {
  Maze();

  @override
  String get name => 'Maze';

  @override
  String get family => 'Maze';

  @override
  String get tag => 'maze';

  @override
  LayoutProperty<Size> get tableSize {
    return const LayoutProperty(
      portrait: Size(9, 6),
      landscape: Size(9, 6),
    );
  }

  @override
  GameSetup construct() {
    return GameSetup(
      setup: {
        for (int i = 0; i < 54; i++)
          Grid(i): PileProperty(
            layout: PileLayout(
              region: LayoutProperty.all(
                Rect.fromLTWH((i % 9).toDouble(), (i ~/ 9).toDouble(), 1, 1),
              ),
            ),
            pickable: const [CardIsOnTop()],
            placeable: const [PileIsEmpty()],
          ),
        const Stock(0): PileProperty(
          layout: const PileLayout(
            region: LayoutProperty.all(Rect.fromLTWH(8, 0, 1, 3)),
          ),
          virtual: true,
          onStart: [
            SetupNewDeck(count: 1, criteria: (card) => card.rank != Rank.king),
          ],
          onSetup: [
            DisperseRandomlyTo<Grid>(
              // Leave last column of first two row empty
              which: (grid) => grid.index != 8 && grid.index != 17,
            ),
            const ForAllPilesOfType<Grid>([FlipAllCardsFaceUp()])
          ],
          pickable: const [NotAllowed()],
          placeable: const [NotAllowed()],
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
