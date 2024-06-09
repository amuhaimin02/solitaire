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

class Spider extends SolitaireGame {
  const Spider({required this.numberOfSuits})
      : assert(
          numberOfSuits == 1 || numberOfSuits == 2 || numberOfSuits == 4,
          'Number of suits can only be 1, 2 or 4',
        );

  final int numberOfSuits;

  @override
  String get name =>
      'Spider $numberOfSuits Suit${numberOfSuits > 1 ? 's' : ''}';

  @override
  String get family => 'Spider';

  @override
  String get tag => 'spider-$numberOfSuits-suit';

  @override
  LayoutProperty<Size> get tableSize {
    return const LayoutProperty(
      portrait: Size(10, 8),
      landscape: Size(11.5, 4.5),
    );
  }

  @override
  Map<Pile, PileProperty> get piles {
    final setupDeck = switch (numberOfSuits) {
      1 => const SetupNewDeck(count: 8, onlySuit: [Suit.spade]),
      2 => const SetupNewDeck(count: 4, onlySuit: [Suit.spade, Suit.heart]),
      4 => const SetupNewDeck(count: 2),
      _ => throw AssertionError('Invalid number of suits')
    };

    return {
      for (int i = 0; i < 8; i++)
        Foundation(i): PileProperty(
          layout: PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(i.toDouble(), 0, 1, 1),
              landscape: Rect.fromLTWH(10.5, i.toDouble() * 0.25, 1, 1),
            ),
            showMarker: LayoutProperty(
              portrait: true,
              landscape: i == 0, // Only show marker on first foundation
            ),
          ),
          pickable: const [NotAllowed()],
          placeable: const [
            BuildupStartsWith(Rank.king),
            CardsHasFullSuit(RankOrder.decreasing),
            PileIsEmpty(),
          ],
        ),
      for (int i = 0; i < 10; i++)
        Tableau(i): PileProperty(
          layout: PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(i.toDouble(), 1.3, 1, 6.7),
              landscape: Rect.fromLTWH(i.toDouble(), 0, 1, 4.5),
            ),
            stackDirection: const LayoutProperty.all(Direction.down),
          ),
          pickable: const [
            CardsAreFacingUp(),
            CardsFollowRankOrder(RankOrder.decreasing),
            CardsAreSameSuit(),
          ],
          placeable: const [
            CardsAreFacingUp(),
            BuildupFollowsRankOrder(RankOrder.decreasing),
            BuildupSameSuit(),
          ],
          afterMove: const [
            FlipTopCardFaceUp(),
          ],
        ),
      const Stock(0): PileProperty(
        layout: const PileLayout(
          region: LayoutProperty(
            portrait: Rect.fromLTWH(9, 0, 1, 1),
            landscape: Rect.fromLTWH(10.5, 3, 1, 1),
          ),
          showCount: LayoutProperty.all(true),
        ),
        pickable: const [NotAllowed()],
        placeable: const [NotAllowed()],
        onStart: [
          setupDeck,
          const FlipAllCardsFaceDown(),
        ],
        onSetup: const [
          DistributeTo<Tableau>(
            distribution: [6, 6, 6, 6, 5, 5, 5, 5, 5, 5],
            afterMove: [
              FlipAllCardsFaceDown(),
              FlipTopCardFaceUp(),
            ],
          ),
        ],
        canTap: const [
          CanRecyclePile(willTakeFrom: Stock(0), limit: 1),
          AllPilesOfType<Tableau>([PileIsNotEmpty()]),
        ],
        onTap: const [
          DistributeTo<Tableau>(
            distribution: [1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
            countAsMove: true,
          ),
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
