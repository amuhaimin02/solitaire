import 'package:flutter/material.dart';

import '../../utils/types.dart';
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

class Yukon extends SolitaireGame {
  const Yukon();

  @override
  String get name => 'Yukon';

  @override
  String get family => 'Yukon';

  @override
  String get tag => 'yukon';

  @override
  LayoutProperty<Size> get tableSize {
    return const LayoutProperty(
      portrait: Size(7, 6),
      landscape: Size(10, 4),
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
              landscape: Rect.fromLTWH(0, i.toDouble(), 1, 1),
            ),
          ),
          markerStartsWith: Rank.ace,
          pickable: const [
            CardIsOnTop(),
          ],
          placeable: const [
            CardIsSingle(),
            CardsAreFacingUp(),
            BuildupStartsWith(rank: Rank.ace),
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
          markerStartsWith: Rank.king,
          pickable: const [
            CardsAreFacingUp(),
          ],
          placeable: const [
            CardsAreFacingUp(),
            BuildupStartsWith(rank: Rank.king),
            BuildupFollowsRankOrder(RankOrder.decreasing),
            BuildupAlternateColors(),
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
      const Stock(): PileProperty(
        layout: const PileLayout(
          region: LayoutProperty(
            portrait: Rect.fromLTWH(6, 0, 1, 1),
            landscape: Rect.fromLTWH(9, 2.5, 1, 1),
          ),
        ),
        virtual: true,
        onStart: const [
          SetupNewDeck(count: 1),
          FlipAllCardsFaceDown(),
        ],
        onSetup: const [
          DistributeTo<Tableau>(
            distribution: [1, 6, 7, 8, 9, 10, 11],
            afterMove: [
              FlipAllCardsFaceDown(),
              FlipTopCardFaceUp(count: 5),
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
      AllPilesOfType<Foundation>([
        PileHasFullSuit(RankOrder.increasing),
      ]),
    ];
  }

  @override
  Iterable<MoveIntent> quickMoveStrategy(
      Pile from, PlayCard card, PlayTable table) sync* {
    // Try placing on foundation pile first
    // For cards from foundation, no need to move to other foundations
    if (from is! Foundation) {
      for (final f in table.allPilesOfType<Foundation>().roll(from: from)) {
        yield MoveIntent(from, f, card);
      }
    }

    // Try placing on tableau next
    for (final t in table.allPilesOfType<Tableau>().roll(from: from)) {
      yield MoveIntent(from, t, card);
    }
  }

  @override
  Iterable<MoveIntent> premoveStrategy(PlayTable table) sync* {
    for (final t in table.allPilesOfType<Tableau>()) {
      for (final f in table.allPilesOfType<Foundation>()) {
        yield MoveIntent(t, f);
      }
    }
  }
}
