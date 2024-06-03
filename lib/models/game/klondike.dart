import 'package:change_case/change_case.dart';
import 'package:flutter/material.dart';

import '../action.dart';
import '../card.dart';
import '../card_list.dart';
import '../direction.dart';
import '../pile.dart';
import '../pile_action.dart';
import '../pile_check.dart';
import '../pile_property.dart';
import '../play_table.dart';
import 'solitaire.dart';

class Klondike extends SolitaireGame {
  const Klondike({required this.numberOfDraws, this.vegasScoring = false});

  @override
  String get name =>
      'Klondike Draw $numberOfDraws${vegasScoring ? ' (Vegas)' : ''}';

  @override
  String get family => 'Klondike';

  @override
  String get tag =>
      'klondike-draw-$numberOfDraws${vegasScoring ? '-vegas' : ''}';

  final int numberOfDraws;

  final bool vegasScoring;

  @override
  LayoutProperty get tableSize {
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
              portrait: Rect.fromLTWH(i.toDouble(), 0, 1, 1),
              landscape: Rect.fromLTWH(0, i.toDouble(), 1, 1),
            ),
          ),
          pickable: const [
            CardIsOnTop(),
          ],
          placeable: const [
            CardsNotComingFrom(Draw()),
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
          onSetup: [
            PickCardsFrom(const Draw(), count: i + 1),
            const FlipAllCardsFaceDown(),
            const FlipTopmostCardFaceUp(),
          ],
          pickable: const [
            CardsAreFacingUp(),
            CardsFollowRankOrder(RankOrder.decreasing),
          ],
          placeable: const [
            CardsNotComingFrom(Draw()),
            CardsAreFacingUp(),
            BuildupStartsWith(rank: Rank.king),
            BuildupFollowsRankOrder(RankOrder.decreasing),
            BuildupAlternateColors(),
          ],
          afterMove: const [
            If(
              conditions: [PileOnTopIsFacingDown()],
              ifTrue: [
                FlipTopCardFaceUp(),
                ObtainScore(score: 100),
              ],
            )
          ],
        ),
      const Draw(): PileProperty(
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
        pickable: const [
          CardIsOnTop(),
        ],
        placeable: const [
          RejectAll(),
        ],
        onTap: const [
          If(
            conditions: [PileIsEmpty()],
            ifTrue: [Redeal(takeFrom: Discard())],
          ),
        ],
        makeMove: (move) => [
          MoveMultipleFromTop(to: move.to, count: numberOfDraws),
        ],
      ),
      const Discard(): PileProperty(
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
          CardsComingFrom(Draw()),
        ],
        onDrop: const [
          FlipAllCardsFaceUp(),
        ],
      ),
    };
  }

  @override
  bool winConditions(PlayTable table) {
    return table.drawPile.isEmpty &&
        table.discardPile.isEmpty &&
        table.allTableauPiles.every((t) => table.get(t).isEmpty);
  }

  @override
  bool canAutoSolve(PlayTable table) {
    for (final t in table.allTableauPiles) {
      final tableau = table.get(t);
      if (tableau.isNotEmpty && !tableau.isAllFacingUp) {
        return false;
      }
    }
    return true;
  }

  @override
  Iterable<MoveIntent> quickMoveStrategy(
      Pile from, PlayCard card, PlayTable table) sync* {
    // Try placing on foundation pile first
    // For cards from foundation, no need to move to other foundations
    if (from is! Foundation) {
      for (final f in table.allFoundationPiles.roll(from: from)) {
        yield MoveIntent(from, f, card);
      }
    }

    // Try placing on tableau next
    for (final t in table.allTableauPiles.roll(from: from)) {
      yield MoveIntent(from, t, card);
    }
  }

  @override
  Iterable<MoveIntent> premoveStrategy(PlayTable table) sync* {
    for (final f in table.allFoundationPiles) {
      yield MoveIntent(const Discard(), f);
    }
    for (final t in table.allTableauPiles) {
      for (final f in table.allFoundationPiles) {
        yield MoveIntent(t, f);
      }
    }
  }

  @override
  Iterable<MoveIntent> autoSolveStrategy(PlayTable table) sync* {
    // Try moving cards from tableau to foundation
    for (final t in table.allTableauPiles) {
      for (final f in table.allFoundationPiles) {
        yield MoveIntent(t, f);
        final discard = table.discardPile;
        if (discard.isNotEmpty) {
          yield MoveIntent(const Discard(), f);
          yield MoveIntent(const Discard(), t);
        }
      }
    }
    yield const MoveIntent(Draw(), Discard());
  }
}
