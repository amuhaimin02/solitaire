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

class SirTommy extends SolitaireGame {
  SirTommy();

  @override
  String get name => 'Sir Tommy';

  @override
  String get family => 'Sir Tommy';

  @override
  String get tag => 'sir-tommy';

  @override
  LayoutProperty<Size> get tableSize {
    return const LayoutProperty(
      portrait: Size(6.5, 6),
      landscape: Size(8, 4),
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
                portrait: Rect.fromLTWH(i.toDouble() + 0.5, 0, 1, 1),
                landscape: Rect.fromLTWH(0, i.toDouble(), 1, 1),
              ),
            ),
            pickable: const [
              CardIsOnTop(),
            ],
            placeable: const [
              CardIsSingle(),
              BuildupStartsWith(Rank.ace),
              BuildupFollowsRankOrder(RankOrder.increasing),
            ],
          ),
        for (int i = 0; i < 4; i++)
          Tableau(i): PileProperty(
            layout: PileLayout(
              region: LayoutProperty(
                portrait: Rect.fromLTWH(i.toDouble() + 0.5, 1.3, 1, 4.7),
                landscape: Rect.fromLTWH(i.toDouble() + 2, 0, 1, 4),
              ),
              stackDirection: const LayoutProperty.all(Direction.down),
            ),
            pickable: const [
              CardIsOnTop(),
            ],
            placeable: const [
              CardsNotComingFrom<Tableau>(),
            ],
          ),
        const Stock(0): PileProperty(
          layout: const PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(5, 1.3, 1, 1),
              landscape: Rect.fromLTWH(7, 1.5, 1, 1),
            ),
            showCount: LayoutProperty.all(true),
          ),
          onStart: const [
            SetupNewDeck(count: 1),
          ],
          onSetup: const [
            FlipAllCardsFaceUp(),
          ],
          canTap: const [CanRecyclePile(willTakeFrom: Stock(0), limit: 1)],
          pickable: const [CardIsOnTop()],
          placeable: const [NotAllowed()],
        ),
      },
    );
  }

  @override
  List<MoveCheck> get objectives {
    return const [
      AllPilesOfType<Foundation>(
        [PileHasFullSuit(rankOrder: RankOrder.increasing)],
      ),
    ];
  }

  @override
  List<MoveAttemptTo> get quickMove {
    return [
      MoveAttemptTo<Foundation>(
        onlyIf: (from, to, args) => from is! Foundation,
      ),
      MoveAttemptTo<Tableau>(
        onlyIf: (from, to, args) => from is! Tableau,
        prioritizeShorterStacks: true,
      ),
    ];
  }
}
