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

class Scorpion extends SolitaireGame {
  Scorpion();

  @override
  String get name => 'Scorpion';

  @override
  String get family => 'Spider';

  @override
  String get tag => 'scorpion';

  @override
  LayoutProperty<Size> get tableSize {
    return const LayoutProperty(
      portrait: Size(8, 6),
      landscape: Size(8.5, 4.5),
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
                portrait: Rect.fromLTWH(i.toDouble(), 0, 1, 6),
                landscape: Rect.fromLTWH(i.toDouble(), 0, 1, 4.5),
              ),
              stackDirection: const LayoutProperty.all(Direction.down),
            ),
            pickable: const [
              CardsAreFacingUp(),
            ],
            placeable: const [
              CardsAreFacingUp(),
              BuildupStartsWith(Rank.king),
              BuildupFollowsRankOrder(RankOrder.decreasing),
              BuildupSameSuit(),
            ],
            afterMove: const [
              FlipTopCardFaceUp(),
            ],
          ),
        const Stock(0): PileProperty(
          layout: const PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(7, 0.5, 1, 1),
              landscape: Rect.fromLTWH(7.5, 0.5, 1, 1),
            ),
            showCount: LayoutProperty.all(true),
          ),
          pickable: const [NotAllowed()],
          placeable: const [NotAllowed()],
          onStart: const [
            SetupNewDeck(count: 1),
          ],
          onSetup: const [
            DistributeTo<Tableau>(
              distribution: [7, 7, 7, 7, 7, 7, 7],
            ),
            ForAllPilesOf([
              Tableau(0),
              Tableau(1),
              Tableau(2),
            ], [
              FlipAllCardsFaceDown(),
              FlipTopCardFaceUp(count: 4),
            ]),
            ForAllPilesOf([
              Tableau(3),
              Tableau(4),
              Tableau(5),
              Tableau(6)
            ], [
              FlipAllCardsFaceUp(),
            ]),
          ],
          canTap: const [
            CanRecyclePile(willTakeFrom: Stock(0), limit: 1),
          ],
          onTap: const [
            DistributeTo<Tableau>(
              distribution: [1, 1, 1, 0, 0, 0, 0],
              countAsMove: true,
            ),
          ],
        ),
      },
    );
  }

  @override
  List<MoveCheck> get objectives {
    return const [
      AllPilesOfType<Tableau>([
        Either(
          first: [PileIsEmpty()],
          second: [PileHasFullSuit(rankOrder: RankOrder.decreasing)],
        )
      ]),
    ];
  }

  @override
  List<MoveAttemptTo> get quickMove {
    return [
      const MoveAttemptTo<Tableau>(roll: true),
    ];
  }
}
