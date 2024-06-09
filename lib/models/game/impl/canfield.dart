import 'package:flutter/material.dart';

import '../../../utils/types.dart';
import '../../direction.dart';
import '../../move_action.dart';
import '../../move_attempt.dart';
import '../../move_check.dart';
import '../../pile.dart';
import '../../pile_property.dart';
import '../../rank_order.dart';
import '../solitaire.dart';

class Canfield extends SolitaireGame {
  const Canfield({required this.numberOfDraws});

  final int numberOfDraws;

  @override
  String get name => 'Canfield Draw $numberOfDraws';

  @override
  String get family => 'Canfield';

  @override
  String get tag => 'canfield-draw-$numberOfDraws';

  @override
  LayoutProperty<Size> get tableSize {
    return const LayoutProperty(
      portrait: Size(7, 6),
      landscape: Size(8.5, 4),
    );
  }

  @override
  GameSetup get setup {
    return {
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
            CardsAreFacingUp(),
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
      for (int i = 0; i < 4; i++)
        Tableau(i): PileProperty(
          layout: PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(i.toDouble() + 2.5, 1.3, 1, 4.7),
              landscape: Rect.fromLTWH(i.toDouble() + 3, 0, 1, 4),
            ),
            stackDirection: const LayoutProperty.all(Direction.down),
          ),
          pickable: const [
            CardsAreFacingUp(),
            CardsFollowRankOrder(RankOrder.decreasing, wrapping: true),
            CardsAreAlternatingColors(),
          ],
          placeable: const [
            CardsAreFacingUp(),
            BuildupFollowsRankOrder(RankOrder.decreasing, wrapping: true),
            BuildupAlternatingColors(),
          ],
        ),
      const Reserve(0): PileProperty(
        layout: const PileLayout(
          region: LayoutProperty(
            portrait: Rect.fromLTWH(0.5, 1.3, 1, 3.7),
            landscape: Rect.fromLTWH(1.5, 0, 1, 3.5),
          ),
          stackDirection: LayoutProperty.all(Direction.down),
        ),
        pickable: const [
          CardIsOnTop(),
        ],
        placeable: const [
          NotAllowed(),
        ],
        afterMove: const [
          FlipTopCardFaceUp(),
        ],
      ),
      const Stock(0): PileProperty(
        layout: const PileLayout(
          region: LayoutProperty(
            portrait: Rect.fromLTWH(6, 0, 1, 1),
            landscape: Rect.fromLTWH(7.5, 2.5, 1, 1),
          ),
          showCount: LayoutProperty.all(true),
        ),
        onStart: const [
          SetupNewDeck(count: 1),
          FlipAllCardsFaceDown(),
        ],
        onSetup: const [
          DistributeTo<Foundation>(
            distribution: [1, 0, 0, 0],
            afterMove: [
              FlipAllCardsFaceUp(),
            ],
          ),
          DistributeTo<Tableau>(
            distribution: [1, 1, 1, 1],
            afterMove: [
              FlipAllCardsFaceDown(),
              FlipTopCardFaceUp(),
            ],
          ),
          DistributeTo<Reserve>(
            distribution: [13],
            afterMove: [
              FlipAllCardsFaceDown(),
              FlipTopCardFaceUp(),
            ],
          ),
        ],
        pickable: const [NotAllowed()],
        placeable: const [NotAllowed()],
        canTap: [
          const CanRecyclePile(
            willTakeFrom: Waste(0),
            limit: intMaxValue,
          ),
        ],
        onTap: [
          If(
            condition: const [PileIsEmpty()],
            ifTrue: const [RecyclePile(takeFrom: Waste(0))],
            ifFalse: [DrawFromTop(to: const Waste(0), count: numberOfDraws)],
          ),
        ],
      ),
      const Waste(0): PileProperty(
        layout: const PileLayout(
          region: LayoutProperty(
            portrait: Rect.fromLTWH(4, 0, 2, 1),
            landscape: Rect.fromLTWH(7.5, 0.5, 1, 2),
          ),
          stackDirection: LayoutProperty(
            portrait: Direction.left,
            landscape: Direction.down,
          ),
          shiftStack: LayoutProperty(
            portrait: true,
            landscape: false,
          ),
          previewCards: LayoutProperty.all(3),
        ),
        pickable: const [
          CardIsOnTop(),
        ],
        placeable: const [
          NotAllowed(),
        ],
      ),
    };
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
        onlyIf: (table, from, to) => from is! Foundation,
      ),
      const MoveAttemptTo<Tableau>(roll: true),
    ];
  }

  @override
  List<MoveAttempt> get premove {
    return const [
      MoveAttempt<Waste, Foundation>(),
      MoveAttempt<Tableau, Foundation>(),
      MoveAttempt<Reserve, Foundation>(),
    ];
  }

  @override
  List<MoveAttempt> get postMove {
    return [
      MoveAttempt<Reserve, Tableau>(
        onlyIf: (table, from, to) => table.get(to).isEmpty,
      ),
    ];
  }
}
