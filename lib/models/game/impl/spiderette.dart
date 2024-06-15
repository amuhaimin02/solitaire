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

class Spiderette extends SolitaireGame {
  Spiderette({required this.numberOfSuits})
      : assert(
          numberOfSuits == 1 || numberOfSuits == 2 || numberOfSuits == 4,
          'Number of suits can only be 1, 2 or 4',
        );

  final int numberOfSuits;

  @override
  String get name =>
      'Spiderette $numberOfSuits Suit${numberOfSuits > 1 ? 's' : ''}';

  @override
  String get family => 'Spider';

  @override
  String get tag => 'spiderette-$numberOfSuits-suit';

  @override
  LayoutProperty<Size> get tableSize {
    return const LayoutProperty(
      portrait: Size(7, 6),
      landscape: Size(10, 4),
    );
  }

  @override
  GameSetup construct() {
    final setupDeck = switch (numberOfSuits) {
      1 => const SetupNewDeck(count: 4, onlySuit: [Suit.spade]),
      2 => const SetupNewDeck(count: 2, onlySuit: [Suit.spade, Suit.heart]),
      4 => const SetupNewDeck(count: 1),
      _ => throw AssertionError('Invalid number of suits')
    };

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
            pickable: const [NotAllowed()],
            placeable: const [
              BuildupStartsWith(Rank.king),
              CardsAreSameSuit(),
              CardsHasFullSuit(RankOrder.decreasing),
              PileIsEmpty(),
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
            ],
            placeable: const [
              CardsAreFacingUp(),
              BuildupFollowsRankOrder(RankOrder.decreasing),
            ],
            afterMove: const [
              FlipTopCardFaceUp(),
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
          pickable: const [NotAllowed()],
          placeable: const [NotAllowed()],
          onStart: [
            setupDeck,
          ],
          onSetup: const [
            DistributeTo<Tableau>(
              distribution: [1, 2, 3, 4, 5, 6, 7],
            ),
            ForAllPilesOfType<Tableau>([
              FlipAllCardsFaceDown(),
              FlipTopCardFaceUp(),
            ])
          ],
          canTap: const [
            CanRecyclePile(willTakeFrom: Stock(0), limit: 1),
            // Edge case: the last distribution will only have 3 cards
            // which is not enough to cover all 7 tableau piles.
            // Therefore, only check the first 3 piles
            Select(
              condition: [PileHasLength(3)],
              ifTrue: [
                AllPilesOf(
                  [Tableau(0), Tableau(1), Tableau(2)],
                  [PileIsNotEmpty()],
                )
              ],
              ifFalse: [
                AllPilesOfType<Tableau>([PileIsNotEmpty()])
              ],
            )
          ],
          onTap: const [
            DistributeTo<Tableau>(
              distribution: [1, 1, 1, 1, 1, 1, 1],
              countAsMove: true,
              allowPartial: true,
            ),
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
  List<MoveAttemptTo> get quickMove {
    return [
      const MoveAttemptTo<Tableau>(roll: true, prioritizeNonEmptySpaces: true),
    ];
  }

  @override
  List<MoveAttempt> get postMove {
    return [
      MoveAttempt<Tableau, Foundation>(cardLength: Rank.values.length),
    ];
  }
}
