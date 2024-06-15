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

class FreeCell extends SolitaireGame {
  FreeCell();

  @override
  String get name => 'FreeCell';

  @override
  String get family => 'FreeCell';

  @override
  String get tag => 'freecell';

  @override
  LayoutProperty<Size> get tableSize {
    return const LayoutProperty(
      portrait: Size(8, 7),
      landscape: Size(11, 4),
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
                portrait: Rect.fromLTWH(i.toDouble(), 0, 1, 1),
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
                portrait: Rect.fromLTWH(i.toDouble(), 1.3, 1, 5.7),
                landscape: Rect.fromLTWH(i.toDouble() + 1.5, 0, 1, 4),
              ),
              stackDirection: const LayoutProperty.all(Direction.down),
            ),
            pickable: const [
              CardsFollowRankOrder(RankOrder.decreasing),
              CardsAreAlternatingColors(),
            ],
            placeable: const [
              BuildupFollowsRankOrder(RankOrder.decreasing),
              BuildupAlternatingColors(),
              FreeCellPowermove(),
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
        for (int i = 0; i < 4; i++)
          Reserve(i): PileProperty(
            layout: PileLayout(
              region: LayoutProperty(
                portrait: Rect.fromLTWH(4 + i.toDouble(), 0, 1, 1),
                landscape: Rect.fromLTWH(10, i.toDouble(), 1, 1),
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
              landscape: Rect.fromLTWH(10, 0, 1, 1),
            ),
          ),
          virtual: true,
          onStart: const [
            SetupNewDeck(count: 1),
          ],
          onSetup: const [
            DistributeTo<Tableau>(
              distribution: [7, 7, 7, 7, 6, 6, 6, 6],
            ),
            ForAllPilesOfType<Tableau>([
              FlipAllCardsFaceUp(),
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
    return [
      MoveAttemptTo<Foundation>(
        onlyIf: (from, to, args) => from is! Foundation,
      ),
      const MoveAttemptTo<Tableau>(roll: true),
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
