import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../action.dart';
import 'solitaire.dart';

import '../card.dart';
import '../direction.dart';
import '../pile.dart';
import '../pile_action.dart';
import '../pile_check.dart';
import '../pile_property.dart';
import '../play_table.dart';

class Spider extends SolitaireGame {
  const Spider({required this.numberOfSuits});

  final int numberOfSuits;

  @override
  String get name =>
      'Spider $numberOfSuits Suit${numberOfSuits > 1 ? 's' : ''}';

  @override
  String get family => 'Spider';

  @override
  String get tag => 'spider-$numberOfSuits-suit';

  @override
  LayoutProperty get tableSize {
    return const LayoutProperty(
      portrait: Size(10, 7),
      landscape: Size(12, 4),
    );
  }

  @override
  Map<Pile, PileProperty> get piles {
    return {
      for (int i = 0; i < 8; i++)
        Foundation(i): PileProperty(
          layout: PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(i.toDouble(), 0, 1, 1),
              landscape: Rect.fromLTWH(0, i.toDouble() * 0.4 + 0.3, 1, 1),
            ),
            showMarker: LayoutProperty(
              portrait: true,
              landscape: i == 0, // Only show marker on first foundation
            ),
          ),
        ),
      for (int i = 0; i < 10; i++)
        Tableau(i): PileProperty(
          layout: PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(i.toDouble(), 1.3, 1, 5.7),
              landscape: Rect.fromLTWH(i.toDouble() + 1, 0, 1, 4),
            ),
            stackDirection: const LayoutProperty.all(Direction.down),
          ),
          onSetup: [
            PickCardsFrom(const Draw(), count: i >= 4 ? 5 : 6),
            const FlipAllCardsFaceDown(),
            const FlipTopCardFaceUp(),
          ],
          pickable: const [
            CardsAreFacingUp(),
            CardsFollowRankOrder(RankOrder.decreasing),
          ],
          placeable: const [
            CardsAreFacingUp(),
            BuildupFollowsRankOrder(RankOrder.decreasing),
            BuildupSameSuit(),
          ],
          onDrop: [
            If(
              conditions: [
                const PileHasFullSuit(RankOrder.decreasing),
              ],
              ifTrue: [
                SendToAnyEmptyPile<Foundation>(count: Rank.values.length)
              ],
            ),
          ],
          afterMove: [
            const If(
              conditions: [PileOnTopIsFacingDown()],
              ifTrue: [FlipTopCardFaceUp()],
            )
          ],
        ),
      const Draw(): PileProperty(
        layout: const PileLayout(
          region: LayoutProperty(
            portrait: Rect.fromLTWH(9, 0, 1, 1),
            landscape: Rect.fromLTWH(11, 1.5, 1, 1),
          ),
          showCount: LayoutProperty.all(true),
        ),
        onStart: [
          switch (numberOfSuits) {
            1 => const SetupNewDeck(count: 8, onlySuit: [Suit.spade]),
            2 =>
              const SetupNewDeck(count: 4, onlySuit: [Suit.spade, Suit.heart]),
            4 => const SetupNewDeck(count: 2),
            _ => throw ArgumentError('Number of suits can only be 1, 2 or 4')
          },
          const FlipAllCardsFaceDown(),
        ],
        onTap: [
          const If(
            conditions: [AllPilesOfTypeAreNotEmpty<Tableau>()],
            ifTrue: [DistributeEquallyToAll<Tableau>(count: 1)],
          ),
        ],
      ),
    };
  }

  @override
  bool winConditions(PlayTable table) {
    return table.allFoundationPiles.every((f) => table.get(f).isNotEmpty);
  }

  @override
  Iterable<MoveIntent> quickMoveStrategy(
      Pile from, PlayCard card, PlayTable table) sync* {
    for (final t in table.allTableauPiles.roll(from: from)) {
      yield MoveIntent(from, t, card);
    }
  }
}
