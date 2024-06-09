import 'dart:ui';

import 'package:flutter/rendering.dart';

import '../action.dart';
import '../card.dart';
import '../direction.dart';
import '../move_action.dart';
import '../move_check.dart';
import '../move_event.dart';
import '../pile.dart';
import '../pile_property.dart';
import '../play_table.dart';
import '../rank_order.dart';
import 'solitaire.dart';

class Penguin extends SolitaireGame {
  const Penguin();

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
  Map<Pile, PileProperty> get piles {
    return {
      for (int i = 0; i < 4; i++)
        Foundation(i): PileProperty(
          layout: PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(i.toDouble() + 1.5, 0, 1, 1),
              landscape: Rect.fromLTWH(0, i.toDouble() + 0.25, 1, 1),
            ),
          ),
          markerStartsWithRelativeTo: const Foundation(0),
          pickable: const [
            CardIsOnTop(),
          ],
          placeable: const [
            CardIsSingle(),
            BuildupStartsWithRelativeTo(Foundation(0)),
            BuildupFollowsRankOrder(RankOrder.increasing),
            BuildupSameSuit(),
          ],
        ),
      for (int i = 0; i < 7; i++)
        Tableau(i): PileProperty(
          layout: PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(i.toDouble(), 2.3, 1, 4.7),
              landscape: Rect.fromLTWH(i.toDouble() + 1.5, 1, 1, 3.5),
            ),
            stackDirection: const LayoutProperty.all(Direction.down),
          ),
          markerStartsWithRelativeTo: const Foundation(0),
          markerStartsWithRankDifference: -1,
          pickable: const [
            CardsFollowRankOrder(RankOrder.decreasing),
            CardsAreSameSuit(),
          ],
          placeable: const [
            BuildupStartsWithRelativeTo(Foundation(0), rankDifference: -1),
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
              portrait: Rect.fromLTWH(i.toDouble(), 1.3, 1, 1),
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
      const Stock(): PileProperty(
        layout: const PileLayout(
          region: LayoutProperty(
            portrait: Rect.fromLTWH(6, 0, 1, 1),
            landscape: Rect.fromLTWH(7.5, 0, 1, 1),
          ),
        ),
        virtual: true,
        onStart: const [
          SetupNewDeck(count: 1),
          FlipAllCardsFaceDown(),
        ],
        onSetup: const [
          ArrangePenguinFoundations(
              firstCardGoesTo: Tableau(0),
              relatedCardsGoTo: [Foundation(0), Foundation(1), Foundation(2)]),
          DistributeTo<Tableau>(
            distribution: [6, 7, 7, 7, 7, 7, 7],
            afterMove: [
              FlipAllCardsFaceUp(),
            ],
          ),
        ],
        pickable: const [NotAllowed()],
        placeable: const [NotAllowed()],
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
  Iterable<MoveIntent> quickMoveStrategy(
      Pile from, PlayCard card, PlayTable table) sync* {
    if (from is! Foundation) {
      for (final f in table.allPilesOfType<Foundation>().roll(from: from)) {
        yield MoveIntent(from, f, card);
      }
    }

    for (final t in table.allPilesOfType<Tableau>().roll(from: from)) {
      yield MoveIntent(from, t, card);
    }

    if (from is! Reserve && from is! Foundation) {
      for (final r in table.allPilesOfType<Reserve>().roll(from: from)) {
        yield MoveIntent(from, r, card);
      }
    }
  }

  @override
  Iterable<MoveIntent> premoveStrategy(PlayTable table) sync* {
    for (final t in table.allPilesOfType<Tableau>()) {
      for (final f in table.allPilesOfType<Foundation>()) {
        yield MoveIntent(t, f);
      }
    }
    for (final r in table.allPilesOfType<Reserve>()) {
      for (final f in table.allPilesOfType<Foundation>()) {
        yield MoveIntent(r, f);
      }
    }
  }
}
