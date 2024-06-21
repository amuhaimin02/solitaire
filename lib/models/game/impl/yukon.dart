import 'package:flutter/material.dart';

import '../../card.dart';
import '../../direction.dart';
import '../../move_action.dart';
import '../../move_attempt.dart';
import '../../move_check.dart';
import '../../move_event.dart';
import '../../pile.dart';
import '../../pile_property.dart';
import '../../rank_order.dart';
import '../solitaire.dart';

class Yukon extends SolitaireGame {
  Yukon();

  @override
  String get name => 'Yukon';

  @override
  String get family => 'Yukon';

  @override
  String get tag => 'yukon';

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
        for (int i = 0; i < 4; i++)
          Foundation(i): PileProperty(
            layout: PileLayout(
              region: LayoutProperty(
                portrait: Rect.fromLTWH(i.toDouble() + 1.5, 0, 1, 1),
                landscape: Rect.fromLTWH(0, i.toDouble(), 1, 1),
              ),
            ),
            pickable: const [
              CardIsOnTop(),
            ],
            placeable: const [
              CardIsSingle(),
              CardsAreFacingUp(),
              BuildupStartsWith(Rank.ace),
              BuildupFollowsRankOrder(RankOrder.increasing),
              BuildupSameSuit(),
            ],
          ),
        for (int i = 0; i < 7; i++)
          Tableau(i): PileProperty(
            layout: PileLayout(
              region: LayoutProperty(
                portrait: Rect.fromLTWH(i.toDouble(), 1.3, 1, 4.7),
                landscape: Rect.fromLTWH(i.toDouble() + 1.5, 0, 1, 4),
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
              BuildupAlternatingColors(),
            ],
            afterMove: const [
              If(
                condition: [PileTopCardIsFacingDown()],
                ifTrue: [
                  FlipTopCardFaceUp(),
                  EmitEvent(TableauReveal()),
                ],
              )
            ],
          ),
        const Stock(0): PileProperty(
          layout: const PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(6, 0, 1, 1),
              landscape: Rect.fromLTWH(7.5, 0, 1, 1),
            ),
          ),
          virtual: true,
          onStart: const [
            SetupNewDeck(count: 1),
          ],
          onSetup: const [
            DistributeTo<Tableau>(
              distribution: [1, 6, 7, 8, 9, 10, 11],
            ),
            ForAllPilesOfType<Tableau>([
              FlipAllCardsFaceDown(),
              FlipTopCardFaceUp(count: 5),
            ])
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
      AllPilesOfType<Foundation>([PileHasFullSuit()]),
    ];
  }

  @override
  List<MoveAttemptTo> get quickMove {
    return const [
      MoveAttemptTo<Foundation>(),
      MoveAttemptTo<Tableau>(),
    ];
  }

  @override
  List<MoveAttempt> get premove {
    return const [MoveAttempt<Tableau, Foundation>()];
  }
}
