import 'dart:ui';

import 'package:flutter/material.dart';

import '../action.dart';
import '../card.dart';
import '../direction.dart';
import '../move_action.dart';
import '../move_check.dart';
import '../pile.dart';
import '../pile_property.dart';
import '../play_table.dart';
import 'solitaire.dart';

class Golf extends SolitaireGame {
  const Golf();

  @override
  String get name => 'Golf';

  @override
  String get family => 'Golf';

  @override
  String get tag => 'golf';

  @override
  LayoutProperty<Size> get tableSize {
    return const LayoutProperty(
      portrait: Size(7, 5.5),
      landscape: Size(8.5, 4),
    );
  }

  @override
  Map<Pile, PileProperty> get piles {
    return {
      for (int i = 0; i < 7; i++)
        Tableau(i): PileProperty(
          layout: PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(i.toDouble(), 0, 1, 3),
              landscape: Rect.fromLTWH(i.toDouble(), 0, 1, 3),
            ),
            stackDirection: const LayoutProperty.all(Direction.down),
          ),
          markerStartsWith: Rank.king,
          pickable: const [
            CardIsSingle(),
          ],
          placeable: const [NotAllowed()],
        ),
      const Stock(): PileProperty(
        layout: const PileLayout(
          region: LayoutProperty(
            portrait: Rect.fromLTWH(3, 4.5, 1, 1),
            landscape: Rect.fromLTWH(7.5, 2.5, 1, 1),
          ),
          showCount: LayoutProperty.all(true),
        ),
        onStart: const [
          SetupNewDeck(count: 1),
          FlipAllCardsFaceDown(),
        ],
        onSetup: const [
          DistributeTo<Tableau>(
            distribution: [5, 5, 5, 5, 5, 5, 5],
            afterMove: [
              FlipAllCardsFaceUp(),
            ],
          ),
        ],
        pickable: const [NotAllowed()],
        placeable: const [NotAllowed()],
        canTap: const [
          CanRecyclePile(willTakeFrom: Waste(), limit: 1),
        ],
        onTap: const [
          DrawFromTop(to: Waste(), count: 1),
        ],
      ),
      const Waste(): PileProperty(
        layout: const PileLayout(
          region: LayoutProperty(
            portrait: Rect.fromLTWH(3, 3, 1, 1),
            landscape: Rect.fromLTWH(3, 3, 1, 1),
          ),
        ),
        pickable: const [
          NotAllowed(),
        ],
        placeable: const [
          BuildupOneRankNearer(),
        ],
      ),
    };
  }

  @override
  List<MoveCheck> get objectives {
    return const [
      AllPilesOfType<Tableau>([PileIsEmpty()]),
    ];
  }

  @override
  Iterable<MoveIntent> quickMoveStrategy(
      Pile from, PlayCard card, PlayTable table) sync* {
    if (from is Tableau) {
      yield MoveIntent(from, const Waste(), card);
    }
  }
}
