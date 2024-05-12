import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/card.dart';
import '../models/game_layout.dart';
import '../utils/color_utils.dart';
import 'card_marker.dart';
import 'playing_card.dart';

enum CardStackDirection { topDown, rightToLeft, bottomToFront }

class CardStack extends StatelessWidget {
  const CardStack({
    super.key,
    required this.direction,
    required this.cards,
    this.markerIcon,
    this.showCardCount = false,
    this.shiftCardsOnStack = false,
    this.maxCardsToShow,
    this.onCardTap,
  });

  final CardStackDirection direction;

  final PlayCardList cards;

  final IconData? markerIcon;

  final bool showCardCount;

  final bool shiftCardsOnStack;

  final int? maxCardsToShow;

  final Function(PlayCard card, int index)? onCardTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            if (markerIcon != null)
              Align(
                alignment: _getMarkerAlignment(),
                child: CardMarker(mark: markerIcon!),
              ),
            if (cards.isNotEmpty) ...[
              ..._buildCardWidgets(context, constraints),
              if (showCardCount &&
                  direction == CardStackDirection.bottomToFront)
                Positioned.fill(
                  child: Center(
                    child: CardCountIndicator(count: cards.length),
                  ),
                )
            ],
          ],
        );
      },
    );
  }

  Alignment _getMarkerAlignment() {
    switch (direction) {
      case CardStackDirection.topDown:
        return Alignment.topCenter;
      case CardStackDirection.rightToLeft:
        return Alignment.centerRight;
      case CardStackDirection.bottomToFront:
        return Alignment.center;
    }
  }

  Iterable<Widget> _buildCardWidgets(
      BuildContext context, BoxConstraints constraints) {
    final layout = context.watch<GameLayout>();

    final PlayCardList cardsToShow;

    onTapCallback(PlayCard card, int index) {
      return onCardTap != null ? () => onCardTap!(card, index) : null;
    }

    if (maxCardsToShow != null) {
      cardsToShow = cards
          .getRange(max(cards.length - maxCardsToShow!, 0), cards.length)
          .toList();
    } else {
      cardsToShow = cards;
    }

    switch (direction) {
      case CardStackDirection.topDown:
        final maxStackHeight = constraints.maxHeight;

        // Calculate spacing between cards.
        // There will be a default value, but if there are many cards that can overflow,
        // spacing will be adjusted as to not exceed play container height
        final calculatedGap = min(
          layout.verticalStackGap,
          (maxStackHeight - layout.cardSize.height) / (cardsToShow.length - 1),
        );

        return cardsToShow.mapIndexed((index, card) {
          return Positioned(
            top: switch (shiftCardsOnStack) {
              true => (cardsToShow.length - index - 1) * calculatedGap,
              false => index * calculatedGap,
            },
            child: PlayingCard(
              card: card,
              onTap: onTapCallback(card, index),
            ),
          );
        });
      case CardStackDirection.rightToLeft:
        final maxStackWidth = constraints.maxWidth;

        // Calculate spacing between cards.
        // There will be a default value, but if there are many cards that can overflow,
        // spacing will be adjusted as to not exceed play container height
        final calculatedGap = min(
          layout.horizontalStackGap,
          (maxStackWidth - layout.cardSize.width) / (cardsToShow.length - 1),
        );

        return cardsToShow.mapIndexed((index, card) {
          return Positioned(
            right: switch (shiftCardsOnStack) {
              true => (cardsToShow.length - index - 1) * calculatedGap,
              false => index * calculatedGap,
            },
            child: PlayingCard(
              card: card,
              onTap: onTapCallback(card, index),
            ),
          );
        });

      case CardStackDirection.bottomToFront:
        return [
          PlayingCard(
            card: cardsToShow.last,
            elevation: cardsToShow.length.clamp(2, 24).toDouble(),
            onTap: onTapCallback(cardsToShow.last, cards.length - 1),
          )
        ];
    }
  }
}

class CardCountIndicator extends StatelessWidget {
  const CardCountIndicator({
    super.key,
    required this.count,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    final layout = context.watch<GameLayout>();

    return Container(
      margin: EdgeInsets.all(layout.cardPadding * 3.5),
      padding: EdgeInsets.all(layout.cardPadding * 1.5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }
}
