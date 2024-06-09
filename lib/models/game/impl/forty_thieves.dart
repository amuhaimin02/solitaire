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

class FortyThieves extends SolitaireGame {
  const FortyThieves();

  @override
  String get name => 'Forty Thieves';

  @override
  String get family => 'Forty Thieves';

  @override
  String get tag => 'forty-thieves';

  @override
  LayoutProperty<Size> get tableSize {
    return const LayoutProperty(
      portrait: Size(8, 8),
      landscape: Size(13.5, 5),
    );
  }

  @override
  Map<Pile, PileProperty> get piles {
    return {
      for (int i = 0; i < 8; i++)
        Foundation(i): PileProperty(
          layout: PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(0, i.toDouble(), 1, 1),
              landscape: Rect.fromLTWH(
                  (i ~/ 4).toDouble(), (i % 4).toDouble() + 0.5, 1, 1),
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
      for (int i = 0; i < 10; i++)
        Tableau(i): PileProperty(
          layout: PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(
                  (i % 5).toDouble() + 1.5, (i ~/ 5).toDouble() * 4, 1, 4),
              landscape: Rect.fromLTWH(i.toDouble() + 2.25, 0, 1, 5),
            ),
            stackDirection: const LayoutProperty.all(Direction.down),
          ),
          pickable: const [
            CardsAreFacingUp(),
            CardsAreSameSuit(),
          ],
          placeable: const [
            CardsAreFacingUp(),
            BuildupFollowsRankOrder(RankOrder.decreasing),
            BuildupSameSuit(),
            FreeCellPowermove(),
          ],
        ),
      const Stock(0): PileProperty(
        layout: const PileLayout(
          region: LayoutProperty(
            portrait: Rect.fromLTWH(7, 4, 1, 1),
            landscape: Rect.fromLTWH(12.5, 3, 1, 1),
          ),
          showCount: LayoutProperty.all(true),
        ),
        pickable: const [NotAllowed()],
        placeable: const [NotAllowed()],
        onStart: [
          const SetupNewDeck(count: 2),
          const FlipAllCardsFaceDown(),
        ],
        onSetup: const [
          DistributeTo<Tableau>(
            distribution: [4, 4, 4, 4, 4, 4, 4, 4, 4, 4],
            afterMove: [
              FlipAllCardsFaceUp(),
            ],
          ),
        ],
        canTap: const [
          CanRecyclePile(limit: 1, willTakeFrom: Waste(0)),
        ],
        onTap: const [
          DrawFromTop(to: Waste(0), count: 1),
        ],
      ),
      const Waste(0): PileProperty(
        layout: const PileLayout(
          region: LayoutProperty(
            portrait: Rect.fromLTWH(7, 1.5, 1, 2),
            landscape: Rect.fromLTWH(12.5, 0.5, 1, 2),
          ),
          stackDirection: LayoutProperty.all(Direction.down),
          previewCards: LayoutProperty.all(5),
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
    ];
  }
}
