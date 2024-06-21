import 'dart:ui';

import 'package:flutter/rendering.dart';

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

class EightOff extends SolitaireGame {
  EightOff();

  @override
  String get name => 'Eight Off';

  @override
  String get family => 'FreeCell';

  @override
  String get tag => 'eight-off';

  @override
  LayoutProperty<Size> get tableSize {
    return const LayoutProperty(
      portrait: Size(8, 7),
      landscape: Size(12, 4),
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
                portrait: Rect.fromLTWH(i.toDouble() + 2, 0, 1, 1),
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
              BuildupSameSuit(),
            ],
          ),
        for (int i = 0; i < 8; i++)
          Tableau(i): PileProperty(
            layout: PileLayout(
              region: LayoutProperty(
                portrait: Rect.fromLTWH(i.toDouble(), 2, 1, 5),
                landscape: Rect.fromLTWH(i.toDouble() + 1.5, 0, 1, 4),
              ),
              stackDirection: const LayoutProperty.all(Direction.down),
            ),
            pickable: const [
              CardsFollowRankOrder(RankOrder.decreasing),
              CardsAreSameSuit(),
            ],
            placeable: const [
              BuildupFollowsRankOrder(RankOrder.decreasing),
              BuildupSameSuit(),
              BuildupStartsWith(Rank.king),
              FreeCellPowermove(countEmptyTableaus: false),
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
        for (int i = 0; i < 8; i++)
          Reserve(i): PileProperty(
            layout: PileLayout(
              region: LayoutProperty(
                portrait: Rect.fromLTWH(i.toDouble(), 1, 1, 1),
                landscape: Rect.fromLTWH(
                    10 + (i ~/ 4).toDouble(), (i % 4).toDouble(), 1, 1),
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
              portrait: Rect.fromLTWH(7, 0, 1, 1),
              landscape: Rect.fromLTWH(11, 0, 1, 1),
            ),
          ),
          virtual: true,
          onStart: const [
            SetupNewDeck(count: 1),
          ],
          onSetup: const [
            DistributeTo<Tableau>(
              distribution: [6, 6, 6, 6, 6, 6, 6, 6],
            ),
            DistributeTo<Reserve>(
              distribution: [1, 1, 1, 1, 0, 0, 0, 0],
            ),
            ForAllPilesOfType<Tableau>([FlipAllCardsFaceUp()]),
            ForAllPilesOfType<Reserve>([FlipAllCardsFaceUp()])
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
