import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../card.dart';
import '../../direction.dart';
import '../../game_theme.dart';
import '../../move_action.dart';
import '../../move_attempt.dart';
import '../../move_check.dart';
import '../../pile.dart';
import '../../pile_property.dart';
import '../solitaire.dart';

class GrandfathersClock extends SolitaireGame {
  GrandfathersClock();

  @override
  String get name => 'Grandfather\'s Clock';

  @override
  String get family => 'Others';

  @override
  String get tag => 'grandfathers-clock';

  @override
  LayoutProperty<Size> get tableSize {
    return const LayoutProperty(
      portrait: Size(8, 8),
      landscape: Size(11, 5),
    );
  }

  // List of starting cards on clock dial
  static const _clockDialStartingCards = [
    PlayCard(Rank.nine, Suit.club),
    PlayCard(Rank.ten, Suit.heart),
    PlayCard(Rank.jack, Suit.spade),
    PlayCard(Rank.queen, Suit.diamond),
    PlayCard(Rank.king, Suit.club),
    PlayCard(Rank.two, Suit.heart),
    PlayCard(Rank.three, Suit.spade),
    PlayCard(Rank.four, Suit.diamond),
    PlayCard(Rank.five, Suit.club),
    PlayCard(Rank.six, Suit.heart),
    PlayCard(Rank.seven, Suit.spade),
    PlayCard(Rank.eight, Suit.diamond),
  ];

  static const _clockDialTargetRank = [
    Rank.queen,
    Rank.ace,
    Rank.two,
    Rank.three,
    Rank.four,
    Rank.five,
    Rank.six,
    Rank.seven,
    Rank.eight,
    Rank.nine,
    Rank.ten,
    Rank.jack,
  ];

  @override
  GameSetup construct() {
    const clockCenterPortrait = Point<double>(3.5, 1.75);
    const clockCenterLandscape = Point<double>(2.8, 2);
    const verticalRadius = 1.75;
    final horizontalRadius =
        verticalRadius / cardSizeRatio.width * cardSizeRatio.height;

    double computeRotation(int index) {
      final absoluteAngle = index / 12 * (2 * pi);

      // To ensure rotation animation doesn't look weird (e.g. making anticlockwise full turn even when moving from 359 to 0 degrees),
      // angles will be in range of -pi < x <= pi instead of 0 <= x < 2*pi
      if (absoluteAngle > pi) {
        return absoluteAngle - 2 * pi;
      } else {
        return absoluteAngle;
      }
    }

    LayoutProperty<Rect> computeClockPosition(int index) {
      final angle = computeRotation(index);
      return LayoutProperty(
        portrait: Rect.fromLTWH(
          clockCenterPortrait.x + sin(angle) * horizontalRadius,
          clockCenterPortrait.y - cos(angle) * verticalRadius,
          1,
          1,
        ),
        landscape: Rect.fromLTWH(
          clockCenterLandscape.x + sin(angle) * horizontalRadius,
          clockCenterLandscape.y - cos(angle) * verticalRadius,
          1,
          1,
        ),
      );
    }

    return GameSetup(
      setup: {
        for (int i = 0; i < 12; i++)
          Grid(i): PileProperty(
            layout: PileLayout(
              region: computeClockPosition(i),
              rotation: LayoutProperty.all(computeRotation(i)),
            ),
            pickable: const [
              CardIsOnTop(),
              PileIsNotLeftEmpty(),
            ],
            placeable: const [
              CardIsSingle(),
              BuildupRankAbove(gap: 1, wrapping: true),
              BuildupSameSuit(),
            ],
          ),
        for (int i = 0; i < 8; i++)
          Tableau(i): PileProperty(
            layout: PileLayout(
              region: LayoutProperty(
                portrait: Rect.fromLTWH(
                  i.toDouble(),
                  5,
                  1,
                  3,
                ),
                landscape: Rect.fromLTWH(
                  (i % 4).toDouble() + 7,
                  (i ~/ 4).toDouble() * 2.5,
                  1,
                  2.5,
                ),
              ),
              stackDirection: const LayoutProperty.all(Direction.down),
            ),
            pickable: const [
              CardIsOnTop(),
            ],
            placeable: const [
              BuildupRankBelow(gap: 1, wrapping: true),
            ],
          ),
        const Stock(0): PileProperty(
          layout: PileLayout(
            region: LayoutProperty(
              portrait: Rect.fromLTWH(
                clockCenterPortrait.x,
                clockCenterPortrait.y,
                1,
                1,
              ),
              landscape: Rect.fromLTWH(
                clockCenterLandscape.x,
                clockCenterLandscape.y,
                1,
                1,
              ),
            ),
            showCount: const LayoutProperty.all(true),
          ),
          virtual: true,
          onStart: const [
            SetupNewDeck(count: 1),
          ],
          onSetup: [
            for (int i = 0; i < 12; i++)
              FindCardsAndMove(
                which: (card, _) =>
                    card.isSameSuitAndRank(_clockDialStartingCards[i]),
                firstCardOnly: true,
                moveTo: Grid(i),
              ),
            const ForAllPilesOfType<Grid>([FlipAllCardsFaceUp()]),
            const DistributeTo<Tableau>(
              distribution: [5, 5, 5, 5, 5, 5, 5, 5],
            ),
          ],
          pickable: const [NotAllowed()],
          placeable: const [NotAllowed()],
        ),
      },
    );
  }

  @override
  List<MoveCheck> get objectives {
    // Easier to check tableau instead of foundation
    return const [
      AllPilesOfType<Tableau>([PileIsEmpty()])
    ];
  }

  @override
  List<MoveAttemptTo> get quickMove {
    return const [
      MoveAttemptTo<Grid>(),
      MoveAttemptTo<Tableau>(roll: true),
    ];
  }
}
