import 'dart:ui';

import 'package:flutter/rendering.dart';

import '../../direction.dart';
import '../../move_action.dart';
import '../../move_attempt.dart';
import '../../move_check.dart';
import '../../move_event.dart';
import '../../pile.dart';
import '../../pile_property.dart';
import '../../rank_order.dart';
import '../solitaire.dart';

class Penguin extends SolitaireGame {
  Penguin();

  @override
  String get name => 'Penguin';

  @override
  String get family => 'FreeCell';

  @override
  String get tag => 'penguin';

  @override
  LayoutProperty<Size> get tableSize {
    return const LayoutProperty(
      portrait: Size(7, 7),
      landscape: Size(8.5, 4.5),
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
                landscape: Rect.fromLTWH(0, i.toDouble() + 0.25, 1, 1),
              ),
            ),
            pickable: const [
              CardIsOnTop(),
              PileIsNotLeftEmpty(),
            ],
            placeable: const [
              CardIsSingle(),
              BuildupStartsWith.relativeTo([
                Foundation(0),
                Foundation(1),
                Foundation(2),
                Foundation(3),
              ]),
              BuildupFollowsRankOrder(RankOrder.increasing, wrapping: true),
              BuildupSameSuit(),
            ],
          ),
        for (int i = 0; i < 7; i++)
          Tableau(i): PileProperty(
            layout: PileLayout(
              region: LayoutProperty(
                portrait: Rect.fromLTWH(i.toDouble(), 2, 1, 5),
                landscape: Rect.fromLTWH(i.toDouble() + 1.5, 1, 1, 3.5),
              ),
              stackDirection: const LayoutProperty.all(Direction.down),
            ),
            pickable: const [
              CardsFollowRankOrder(RankOrder.decreasing),
              CardsAreSameSuit(),
            ],
            placeable: const [
              BuildupStartsWith.relativeTo(
                [
                  Foundation(0),
                  Foundation(1),
                  Foundation(2),
                  Foundation(3),
                ],
                rankDifference: -1,
                wrapping: true,
              ),
              BuildupFollowsRankOrder(RankOrder.decreasing),
              BuildupSameSuit(),
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
        for (int i = 0; i < 7; i++)
          Reserve(i): PileProperty(
            layout: PileLayout(
              region: LayoutProperty(
                portrait: Rect.fromLTWH(i.toDouble(), 1, 1, 1),
                landscape: Rect.fromLTWH(i.toDouble() + 1.5, 0, 1, 1),
              ),
            ),
            pickable: const [
              CardIsSingle(),
              CardIsOnTop(),
            ],
            placeable: const [
              CardIsSingle(),
              CardsAreFacingUp(),
              PileIsEmpty(),
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
          onSetup: [
            for (int i = 0; i < 3; i++)
              FindCardsAndMove(
                which: (card, cardsOnPile) {
                  final refCard = cardsOnPile.first;
                  return card != refCard && card.rank == refCard.rank;
                },
                firstCardOnly: true,
                moveTo: Foundation(i),
              ),
            const DistributeTo<Tableau>(
              distribution: [7, 7, 7, 7, 7, 7, 7],
            ),
            const ForAllPilesOfType<Tableau>([FlipAllCardsFaceUp()]),
            const ForAllPilesOfType<Foundation>([FlipAllCardsFaceUp()]),
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
    return [
      MoveAttemptTo<Foundation>(
        onlyIf: (from, to, args) => from is! Foundation,
      ),
      const MoveAttemptTo<Tableau>(),
      MoveAttemptTo<Reserve>(
        onlyIf: (from, to, args) => from is Tableau,
      ),
    ];
  }

  @override
  List<MoveAttempt> get premove {
    return const [
      MoveAttempt<Tableau, Foundation>(),
      MoveAttempt<Reserve, Foundation>(),
    ];
  }
}
