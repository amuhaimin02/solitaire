import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../card.dart';
import '../../direction.dart';
import '../../move_action.dart';
import '../../move_attempt.dart';
import '../../move_check.dart';
import '../../pile.dart';
import '../../pile_property.dart';
import '../../rank_order.dart';
import '../solitaire.dart';

class SimpleSimon extends SolitaireGame {
  SimpleSimon();

  @override
  String get name => 'Simple Simon';

  @override
  String get family => 'Spider';

  @override
  String get tag => 'simple-simon';

  @override
  LayoutProperty<Size> get tableSize {
    return const LayoutProperty(
      portrait: Size(10, 8),
      landscape: Size(11.5, 4.5),
    );
  }

  @override
  GameSetup construct() {
    return GameSetup(
      setup: {
        for (int i = 0; i < 4; i++)
          Foundation(i): PileProperty(
            layout: PileLayout(
              region: LayoutProperty(
                portrait: Rect.fromLTWH(i.toDouble() + 3, 0, 1, 1),
                landscape: Rect.fromLTWH(0, i.toDouble(), 1, 1),
              ),
            ),
            pickable: const [NotAllowed()],
            placeable: const [
              BuildupStartsWith(Rank.king),
              CardsAreSameSuit(),
              CardsHasFullSuit(RankOrder.decreasing),
              PileIsEmpty(),
            ],
          ),
        for (int i = 0; i < 10; i++)
          Tableau(i): PileProperty(
            layout: PileLayout(
              region: LayoutProperty(
                portrait: Rect.fromLTWH(i.toDouble(), 1.3, 1, 6.7),
                landscape: Rect.fromLTWH(i.toDouble() + 1.5, 0, 1, 4.5),
              ),
              stackDirection: const LayoutProperty.all(Direction.down),
            ),
            pickable: const [
              CardsAreFacingUp(),
              CardsFollowRankOrder(RankOrder.decreasing),
              CardsAreSameSuit(),
            ],
            placeable: const [
              CardsAreFacingUp(),
              BuildupFollowsRankOrder(RankOrder.decreasing),
            ],
          ),
        const Stock(0): PileProperty(
          layout: const PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(9, 0, 1, 1),
              landscape: Rect.fromLTWH(10.5, 3, 1, 1),
            ),
            showCount: LayoutProperty.all(true),
          ),
          pickable: const [NotAllowed()],
          placeable: const [NotAllowed()],
          virtual: true,
          onStart: const [
            SetupNewDeck(count: 1),
          ],
          onSetup: const [
            DistributeTo<Tableau>(
              distribution: [8, 8, 8, 7, 6, 5, 4, 3, 2, 1],
              afterMove: [
                FlipAllCardsFaceUp(),
              ],
            ),
          ],
        ),
      },
    );
  }

  @override
  List<MoveCheck> get objectives {
    return const [
      AllPilesOfType<Foundation>([PileHasFullSuit()]),
    ];
  }

  @override
  List<MoveAttemptTo> get quickMove {
    return [
      const MoveAttemptTo<Tableau>(roll: true, prioritizeNonEmptySpaces: true),
    ];
  }

  @override
  List<MoveAttempt> get postMove {
    return [
      MoveAttempt<Tableau, Foundation>(cardLength: Rank.values.length),
    ];
  }
}
