import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

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

class Klondike extends SolitaireGame {
  const Klondike({required this.numberOfDraws, this.vegasScoring = false});

  final int numberOfDraws;

  final bool vegasScoring;

  @override
  String get name =>
      'Klondike Draw $numberOfDraws${vegasScoring ? ' (Vegas)' : ''}';

  @override
  String get family => 'Klondike';

  @override
  String get tag =>
      'klondike-draw-$numberOfDraws${vegasScoring ? '-vegas' : ''}';

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
              portrait: Rect.fromLTWH(i.toDouble(), 0, 1, 1),
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
            PickCardsFrom(const Stock(), count: i + 1),
            const FlipAllCardsFaceDown(),
            const FlipTopCardFaceUp(),
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
          ],
          afterMove: const [
            If(
              condition: [PileTopCardIsFacingDown()],
              ifTrue: [
                FlipTopCardFaceUp(),
                ObtainScore(score: 100),
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
          showCount: LayoutProperty.all(true),
        ),
        onStart: const [
          SetupNewDeck(count: 1),
          FlipAllCardsFaceDown(),
        ],
        onTap: [
          If(
            condition: const [PileIsEmpty()],
            ifTrue: const [RecyclePile(takeFrom: Waste())],
            ifFalse: [DrawFromTop(to: const Waste(), count: numberOfDraws)],
          ),
        ],
      ),
      const Waste(): PileProperty(
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
      ),
    };
  }

  @override
  bool winConditions(PlayTable table) {
    return table
            .allPilesOfType<Foundation>()
            .map((f) => table.get(f).length)
            .sum >=
        PlayCard.numberOfCardsInDeck;
  }

  @override
  bool canAutoSolve(PlayTable table) {
    for (final t in table.allPilesOfType<Tableau>()) {
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
    for (final f in table.allPilesOfType<Foundation>()) {
      yield MoveIntent(const Waste(), f);
    }
    for (final t in table.allPilesOfType<Tableau>()) {
      for (final f in table.allPilesOfType<Foundation>()) {
        yield MoveIntent(t, f);
      }
    }
  }

  @override
  Iterable<MoveIntent> autoSolveStrategy(PlayTable table) sync* {
    // Try moving cards from tableau to foundation
    for (final t in table.allPilesOfType<Tableau>()) {
      for (final f in table.allPilesOfType<Foundation>()) {
        yield MoveIntent(t, f);
        for (final w in table.allPilesOfType<Waste>()) {
          final cardsOnWaste = table.get(w);
          if (cardsOnWaste.isNotEmpty) {
            yield MoveIntent(w, f);
          }
        }
      }
    }
    yield const MoveIntent(Stock(), Stock());
  }
}
