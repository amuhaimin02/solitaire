import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../card.dart';
import '../../direction.dart';
import '../../move_action.dart';
import '../../move_attempt.dart';
import '../../move_check.dart';
import '../../pile.dart';
import '../../pile_property.dart';
import '../solitaire.dart';

class AcesUp extends SolitaireGame {
  AcesUp();

  @override
  String get name => 'Aces Up';

  @override
  String get family => 'Discarding';

  @override
  String get tag => 'aces-up';

  @override
  LayoutProperty<Size> get tableSize {
    return const LayoutProperty(
      portrait: Size(7, 5),
      landscape: Size(8, 4),
    );
  }

  @override
  GameSetup construct() {
    return GameSetup(
      setup: {
        for (int i = 0; i < 4; i++)
          Tableau(i): PileProperty(
            layout: PileLayout(
              region: LayoutProperty(
                portrait: Rect.fromLTWH(i.toDouble() + 1.5, 0, 1, 6),
                landscape: Rect.fromLTWH(i.toDouble() + 2, 0, 1, 4),
              ),
              stackDirection: const LayoutProperty.all(Direction.down),
            ),
            pickable: const [
              CardIsOnTop(),
            ],
            placeable: const [
              PileIsEmpty(),
            ],
          ),
        const Waste(0): PileProperty(
          layout: const PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(0, 0.5, 1, 1),
              landscape: Rect.fromLTWH(0, 1.5, 1, 1),
            ),
          ),
          pickable: const [NotAllowed()],
          placeable: [
            const CardIsSingle(),
            const CardsAreFacingUp(),
            CardRankIsLowestAmong<Tableau>(
              compareWith: (cards, refCard) {
                final lastCard = cards.lastOrNull;
                if (refCard.suit == lastCard?.suit) {
                  return lastCard;
                } else {
                  return null;
                }
              },
              ignoreCardsWith: (card) => card.rank == Rank.ace,
            ),
          ],
        ),
        const Stock(0): PileProperty(
          layout: const PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(6, 0.5, 1, 1),
              landscape: Rect.fromLTWH(7, 1.5, 1, 1),
            ),
            showCount: LayoutProperty.all(true),
          ),
          onStart: const [
            SetupNewDeck(count: 1),
          ],
          canTap: const [CanRecyclePile(willTakeFrom: Stock(0), limit: 1)],
          onTap: const [
            DistributeTo<Tableau>(
              distribution: [1, 1, 1, 1],
              countAsMove: true,
            )
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
      AllPilesOfType<Tableau>(
        [PileHasLength(1), PileTopCardIsRank(Rank.ace)],
      ),
    ];
  }

  @override
  List<MoveAttemptTo> get quickMove {
    return const [
      MoveAttemptTo<Waste>(),
      MoveAttemptTo<Tableau>(),
    ];
  }
}
