import 'package:flutter/material.dart';

import '../../../utils/types.dart';
import '../../action.dart';
import '../../card.dart';
import '../../move_action.dart';
import '../../move_attempt.dart';
import '../../move_check.dart';
import '../../pile.dart';
import '../../pile_property.dart';
import '../solitaire.dart';

class Pyramid extends SolitaireGame {
  Pyramid();

  @override
  String get name => 'Pyramid';

  @override
  String get family => 'Pyramid';

  @override
  String get tag => 'pyramid';

  @override
  LayoutProperty<Size> get tableSize {
    return const LayoutProperty(
      portrait: Size(7, 5.5),
      landscape: Size(8.5, 4),
    );
  }

  @override
  GameSetup construct() {
    return GameSetup(
      setup: {
        for (int y = 0; y < 7; y++)
          for (int x = 0; x <= y; x++)
            Grid(x, y): PileProperty(
              layout: PileLayout(
                region: LayoutProperty(
                  portrait: Rect.fromLTWH(x * 1.0 + 3 - y * 0.5, y * 0.5, 1, 1),
                  landscape:
                      Rect.fromLTWH(x * 1.0 + 3 - y * 0.5, y * 0.5, 1, 1),
                ),
                showMarker: const LayoutProperty.all(false),
              ),
              pickable: const [
                PileIsExposed(),
              ],
              placeable: const [
                PileIsExposed(),
                BuildupRankValueAddUpTo(13),
              ],
            ),
        const Foundation(0): PileProperty(
          layout: const PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(0.5, 4.5, 1, 1),
              landscape: Rect.fromLTWH(0, 0.5, 1, 1),
            ),
          ),
          pickable: const [
            NotAllowed(),
          ],
          placeable: const [
            CardsRankValueAddUpTo(13),
          ],
        ),
        const Stock(0): PileProperty(
          layout: const PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(5, 4.5, 1, 1),
              landscape: Rect.fromLTWH(7.5, 2.5, 1, 1),
            ),
            showCount: LayoutProperty.all(true),
          ),
          onStart: const [
            SetupNewDeck(count: 1),
          ],
          onSetup: [
            DistributeTo<Grid>(
              distribution: List.filled(28, 1),
            ),
            const FlipAllCardsFaceUp(),
          ],
          canTap: const [
            CanRecyclePile(
              limit: intMaxValue,
              willTakeFrom: Waste(0),
            ),
          ],
          onTap: const [
            If(
              condition: [PileIsEmpty()],
              ifTrue: [RecyclePile(takeFrom: Waste(0), faceUp: true)],
              ifFalse: [
                If(
                  condition: [PileTopCardIsRank(Rank.king)],
                  ifTrue: [MoveNormally(to: Foundation(0), count: 1)],
                  ifFalse: [DrawFromTop(to: Waste(0), count: 1)],
                ),
              ],
            ),
          ],
          pickable: const [],
          placeable: const [
            BuildupRankValueAddUpTo(13),
          ],
        ),
        const Waste(0): PileProperty(
          layout: const PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(3.5, 4.5, 1, 1),
              landscape: Rect.fromLTWH(7.5, 0.5, 1, 1),
            ),
          ),
          pickable: const [],
          placeable: const [
            BuildupRankValueAddUpTo(13),
          ],
        ),
      },
    );
  }

  @override
  List<MoveCheck> get objectives {
    return const [
      AllPilesOfType<Grid>([PileIsEmpty()]),
    ];
  }

  @override
  List<MoveAttemptTo> get quickMove {
    return const [
      MoveAttemptTo<Grid>(),
      MoveAttemptTo<Foundation>(),
      MoveAttemptTo<Waste>(),
      MoveAttemptTo<Stock>(),
    ];
  }

  static bool _recentMoveTargetIsStock(
      Pile from, Pile to, MoveAttemptArgs args) {
    // Only do matching on last moved cards
    if (args.lastAction?.move?.to != from) {
      return false;
    }

    // Prevent automatic movement if stock card is just revealed.
    // In this case, top two cards might move to foundation they happens to be a perfect pair
    return args.lastAction?.move?.to is Stock;
  }

  static bool _recentActionIsNotADraw(
      Pile from, Pile to, MoveAttemptArgs args) {
    // Only do matching on last moved cards
    if (args.lastAction?.move?.to != from) {
      return false;
    }

    // Prevent automatic movement if top cards on stock and waste pile make up a pair.
    // This avoids unintended moves. However, players can still make a match by
    // dragging the cards manually on top of each other, which triggers a Move instead
    // of tapping (triggers a Draw)
    return args.lastAction is! Draw;
  }

  @override
  List<MoveAttempt> get postMove {
    return const [
      MoveCompletedPairs<Grid, Foundation>(),
      MoveCompletedPairs<Stock, Foundation>(onlyIf: _recentMoveTargetIsStock),
      MoveCompletedPairs<Waste, Foundation>(onlyIf: _recentActionIsNotADraw),
    ];
  }
}
