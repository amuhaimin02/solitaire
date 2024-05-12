import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../models/card.dart';
import '../models/game_layout.dart';
import '../models/game_state.dart';
import '../utils/color_utils.dart';

class PlayingCard extends StatelessWidget {
  const PlayingCard(
      {super.key, required this.card, this.elevation, this.onTap});

  final PlayCard card;
  final double? elevation;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final layout = context.watch<GameLayout>();
    final gameState = context.watch<GameState>();
    final colorScheme = Theme.of(context).colorScheme;

    // bool highlight = gameState.lastCardMoved?.contains(card) ?? false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(layout.cardPadding),
        width: layout.cardSize.width,
        height: layout.cardSize.height,
        // decoration: highlight
        //     ? BoxDecoration(
        //         borderRadius: BorderRadius.circular(8),
        //         color: colorScheme.tertiary,
        //       )
        //     : null,
        child: Material(
          borderRadius: BorderRadius.circular(8),
          elevation: elevation ?? 2,
          child: card.flipped ? const CardCover() : CardFace(card: card),
        ),
      ),
    );
  }
}

class CardFace extends StatelessWidget {
  const CardFace({super.key, required this.card});

  final PlayCard card;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final layout = context.watch<GameLayout>();

    final spacingFactor = layout.cardSize.width * 0.05;
    final labelSizingFactor = layout.cardSize.width * 0.32;
    final iconSizingFactor = layout.cardSize.width * 0.25;

    final cardMarkingColor = switch (card.suit.group) {
      'R' => colorScheme.primary,
      'B' || _ => colorScheme.tertiary,
    };

    final iconSvgPath = 'assets/${card.suit.name}.svg';

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: spacingFactor * 0.4,
              horizontal: spacingFactor * 1.2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  card.value.symbol,
                  style: TextStyle(
                    fontSize: labelSizingFactor,
                    fontWeight: FontWeight.bold,
                    color: cardMarkingColor,
                  ),
                ),
                SvgPicture.asset(
                  iconSvgPath,
                  width: labelSizingFactor,
                  height: labelSizingFactor,
                  colorFilter:
                      ColorFilter.mode(cardMarkingColor!, BlendMode.srcIn),
                )
              ],
            ),
          ),
          Positioned(
            bottom: -(layout.cardSize.height * 0.1),
            left: -(layout.cardSize.width * 0.1),
            child: SvgPicture.asset(
              iconSvgPath,
              width: iconSizingFactor * 3.5,
              height: iconSizingFactor * 3.5,
              colorFilter: ColorFilter.mode(
                cardMarkingColor.withOpacity(0.15),
                BlendMode.srcIn,
              ),
            ),
          )
        ],
      ),
    );
  }
}

class CardCover extends StatelessWidget {
  const CardCover({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = context.watch<GameLayout>();

    final colorScheme = Theme.of(context).colorScheme;

    final cardColor = colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          width: layout.cardSize.width * 0.1,
          color: cardColor.darken(0.07),
        ),
      ),
    );
  }
}
