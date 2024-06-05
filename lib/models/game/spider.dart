import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../utils/types.dart';
import '../action.dart';
import '../card.dart';
import '../card_list.dart';
import '../direction.dart';
import '../pile.dart';
import '../pile_action.dart';
import '../pile_check.dart';
import '../pile_property.dart';
import '../play_table.dart';
import '../rank_order.dart';
import 'solitaire.dart';

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
      portrait: Size(10, 7),
      landscape: Size(11.5, 4),
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
          placeable: const [
            CardsHasFullSuit(RankOrder.decreasing),
          ],
        ),
      for (int i = 0; i < 10; i++)
        Tableau(i): PileProperty(
          layout: PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(i.toDouble(), 1.3, 1, 5.7),
              landscape: Rect.fromLTWH(i.toDouble(), 0, 1, 4),
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
      const Draw(): PileProperty(
        layout: const PileLayout(
          region: LayoutProperty(
            portrait: Rect.fromLTWH(9, 0, 1, 1),
            landscape: Rect.fromLTWH(10.5, 3, 1, 1),
          ),
          showCount: LayoutProperty.all(true),
        ),
        onStart: [
          setupDeck,
          const FlipAllCardsFaceDown(),
        ],
        onTap: [
          const If(
            condition: [
              PileIsNotEmpty(),
              AllPilesOfTypeAreNotEmpty<Tableau>(),
            ],
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
  Iterable<MoveIntent> postMoveStrategy(PlayTable table) sync* {
    final fullSuitLength = Rank.values.length;

    for (final t in table.allTableauPiles) {
      final cardsOnTableau = table.get(t);
      if (cardsOnTableau.length >= fullSuitLength) {
        final cardToMove =
            cardsOnTableau[cardsOnTableau.length - fullSuitLength];
        // IF there is a full suit streak, try to move it to empty foundation
        if (cardToMove.isFacingUp && cardToMove.rank == Rank.king) {
          final nextEmptyFoundation = table.getEmptyPileOfType<Foundation>();
          if (nextEmptyFoundation != null) {
            yield MoveIntent(t, nextEmptyFoundation, cardToMove);
          }
        }
      }
    }
  }

  @override
  Iterable<MoveIntent> quickMoveStrategy(
      Pile from, PlayCard card, PlayTable table) sync* {
    if (card.rank == Rank.king) {
      for (final f in table.allFoundationPiles) {
        yield MoveIntent(from, f, card);
      }
    }

    final tableau = table.allTableauPiles.roll(from: from).toList();

    int determinePriority(Tableau t) {
      final cardsOnPile = table.get(t);

      if (cardsOnPile.isEmpty) {
        // Empty tableau will be considered last
        return 0;
      }

      if (!cardsOnPile.last.isOneRankOver(card)) {
        // Impossible to move here, this tableau will be discarded
        return -1;
      }

      // Tableau with longer streaks will be prioritized
      return cardsOnPile
          .getSuitStreakFromLast(RankOrder.decreasing, sameSuit: true)
          .length;
    }

    for (final t in tableau.sortedByPriority(determinePriority)) {
      yield MoveIntent(from, t, card);
    }
  }
}
