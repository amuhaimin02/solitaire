import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../card.dart';
import '../../direction.dart';
import '../../move_action.dart';
import '../../move_attempt.dart';
import '../../move_check.dart';
import '../../pile.dart';
import '../../pile_property.dart';
import '../../rank_order.dart';
import '../solitaire.dart';

class TowerOfHanoy extends SolitaireGame {
  TowerOfHanoy();

  @override
  String get name => 'Tower of Hanoy';

  @override
  String get family => 'Others';

  @override
  String get tag => 'tower-of-hanoy';

  @override
  LayoutProperty<Size> get tableSize {
    return const LayoutProperty(
      portrait: Size(5, 3),
      landscape: Size(5, 4),
    );
  }

  @override
  GameSetup construct() {
    return GameSetup(
      setup: {
        for (int i = 0; i < 3; i++)
          Tableau(i): PileProperty(
            layout: PileLayout(
              region: LayoutProperty(
                portrait: Rect.fromLTWH(i.toDouble() + 1, 0, 1, 3),
                landscape: Rect.fromLTWH(i.toDouble() + 1, 0.5, 1, 3),
              ),
              stackDirection: const LayoutProperty.all(Direction.down),
            ),
            pickable: const [
              CardIsOnTop(),
            ],
            placeable: const [
              CardIsSingle(),
              BuildupRankBelow(),
            ],
          ),
        const Stock(0): PileProperty(
          layout: const PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(2, 0, 1, 1),
              landscape: Rect.fromLTWH(2, 0.5, 1, 1),
            ),
            showCount: LayoutProperty.all(true),
          ),
          onStart: [
            SetupNewDeck(
              count: 1,
              onlySuit: [Suit.spade],
              criteria: (card) => card.rank.value < Rank.ten.value,
            ),
          ],
          onSetup: const [
            DistributeTo<Tableau>(distribution: [3, 3, 3]),
            ForAllPilesOfType<Tableau>([FlipAllCardsFaceUp()]),
          ],
          virtual: true,
          pickable: const [NotAllowed()],
          placeable: const [NotAllowed()],
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
          second: [
            PileHasLength(9),
            PileFollowsRankOrder(RankOrder.decreasing)
          ],
        )
      ]),
    ];
  }

  @override
  List<MoveAttemptTo> get quickMove {
    return const [
      MoveAttemptTo<Tableau>(),
    ];
  }
}
