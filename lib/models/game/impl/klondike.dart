import 'package:flutter/material.dart';

import '../../../utils/types.dart';
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

class Klondike extends SolitaireGame {
  Klondike({required this.numberOfDraws, this.vegasScoring = false});

  final int numberOfDraws;

  final bool vegasScoring;

  @override
  String get name =>
      'Klondike Draw $numberOfDraws${vegasScoring ? ' (Vegas)' : ''}';

  @override
  String get family => 'Klondike';

  @override
  String get tag =>
      'klondike-draw-$numberOfDraws${vegasScoring ? '-vegas' : ''}';

  @override
  LayoutProperty<Size> get tableSize {
    return const LayoutProperty(
      portrait: Size(7, 6),
      landscape: Size(10, 4),
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
              CardsFollowRankOrder(RankOrder.decreasing),
              CardsAreAlternatingColors(),
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
              landscape: Rect.fromLTWH(9, 2.5, 1, 1),
            ),
            showCount: LayoutProperty.all(true),
          ),
          onStart: const [
            SetupNewDeck(count: 1),
            FlipAllCardsFaceDown(),
          ],
          onSetup: const [
            DistributeTo<Tableau>(
              distribution: [1, 2, 3, 4, 5, 6, 7],
              afterMove: [
                FlipAllCardsFaceDown(),
                FlipTopCardFaceUp(),
              ],
            ),
          ],
          pickable: const [NotAllowed()],
          placeable: const [NotAllowed()],
          canTap: [
            CanRecyclePile(
              limit: vegasScoring ? numberOfDraws : intMaxValue,
              willTakeFrom: const Waste(0),
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
              landscape: Rect.fromLTWH(9, 0.5, 1, 2),
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
  List<MoveCheck> get canAutoSolve {
    return [
      AllPilesOfType<Tableau>([
        const PileIsEmpty() | const PileIsAllFacingUp(),
      ]),
    ];
  }

  @override
  int determineScore(MoveEvent event) {
    // Scoring according to https://en.wikipedia.org/wiki/Klondike_(solitaire)
    return switch (event) {
      MoveMade(from: Waste(), to: Tableau()) => 5,
      MoveMade(from: Waste(), to: Foundation()) => 10,
      MoveMade(from: Tableau(), to: Foundation()) => 10,
      TableauReveal() => 5,
      MoveMade(from: Foundation(), to: Tableau()) => -15,
      RecycleMade() => -100,
      _ => 0,
    };
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
    return [
      const MoveAttempt<Waste, Foundation>(),
      const MoveAttempt<Tableau, Foundation>(),
    ];
  }

  @override
  List<MoveAttempt> get autoSolve {
    return [
      const MoveAttempt<Tableau, Foundation>(),
      const MoveAttempt<Waste, Foundation>(),
      const MoveAttempt<Stock, Stock>(),
    ];
  }
}
