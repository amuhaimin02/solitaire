import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/rendering.dart';
import 'solitaire.dart';

import '../action.dart';
import '../card.dart';
import '../direction.dart';
import '../pile.dart';
import '../pile_action.dart';
import '../pile_check.dart';
import '../pile_property.dart';
import '../play_table.dart';

class FreeCell extends SolitaireGame {
  const FreeCell();

  @override
  String get name => 'Classic FreeCell';

  @override
  String get family => 'FreeCell';

  @override
  String get tag => 'freecell-classic';

  @override
  LayoutProperty<Size> get tableSize {
    return const LayoutProperty(
      portrait: Size(8, 6),
      landscape: Size(11, 4),
    );
  }

  @override
  Map<Pile, PileProperty> get piles {
    return {
      for (int i = 0; i < 4; i++)
        Foundation(i): PileProperty(
          layout: PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(4 + i.toDouble(), 0, 1, 1),
              landscape: Rect.fromLTWH(0, i.toDouble(), 1, 1),
            ),
          ),
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
      for (int i = 0; i < 8; i++)
        Tableau(i): PileProperty(
          layout: PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(i.toDouble(), 1.3, 1, 4.7),
              landscape: Rect.fromLTWH(i.toDouble() + 1.5, 0, 1, 4),
            ),
            stackDirection: const LayoutProperty.all(Direction.down),
          ),
          onSetup: [
            PickCardsFrom(const Draw(), count: i >= 4 ? 6 : 7),
            const FlipAllCardsFaceUp(),
          ],
          pickable: const [
            CardsAreFacingUp(),
            CardsFollowRankOrder(RankOrder.decreasing),
          ],
          placeable: const [
            CardsAreFacingUp(),
            BuildupStartsWith(rank: Rank.king),
            BuildupFollowsRankOrder(RankOrder.decreasing),
            BuildupAlternateColors(),
            FreeCellPowermove(),
          ],
          afterMove: const [
            If(
              condition: [PileOnTopIsFacingDown()],
              ifTrue: [
                FlipTopCardFaceUp(),
                ObtainScore(score: 100),
              ],
            )
          ],
        ),
      for (int i = 0; i < 4; i++)
        Reserve(i): PileProperty(
          layout: PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(i.toDouble(), 0, 1, 1),
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
      const Draw(): PileProperty(
        layout: const PileLayout(
          region: LayoutProperty(
            portrait: Rect.fromLTWH(0, 0, 1, 1),
            landscape: Rect.fromLTWH(10, 0, 1, 1),
          ),
        ),
        virtual: true,
        onStart: const [
          SetupNewDeck(count: 1),
          FlipAllCardsFaceDown(),
        ],
      ),
    };
  }

  @override
  bool winConditions(PlayTable table) {
    return table.allFoundationPiles.map((f) => table.get(f).length).sum >=
        PlayCard.numberOfCardsInDeck;
  }

  @override
  Iterable<MoveIntent> quickMoveStrategy(
      Pile from, PlayCard card, PlayTable table) sync* {
    if (from is! Foundation) {
      for (final f in table.allFoundationPiles.roll(from: from)) {
        yield MoveIntent(from, f, card);
      }
    }

    for (final t in table.allTableauPiles.roll(from: from)) {
      yield MoveIntent(from, t, card);
    }

    if (from is! Reserve) {
      for (final r in table.alLReservePiles.roll(from: from)) {
        yield MoveIntent(from, r, card);
      }
    }
  }

  @override
  Iterable<MoveIntent> premoveStrategy(PlayTable table) sync* {
    for (final t in table.allTableauPiles) {
      for (final f in table.allFoundationPiles) {
        yield MoveIntent(t, f);
      }
    }
    for (final r in table.alLReservePiles) {
      for (final f in table.allFoundationPiles) {
        yield MoveIntent(r, f);
      }
    }
  }
}
