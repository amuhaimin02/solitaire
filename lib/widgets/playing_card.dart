import 'package:flutter/material.dart' hide Action;
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
    final colorScheme = Theme.of(context).colorScheme;
    final latestAction =
        context.select<GameState, Action?>((s) => s.latestAction);

    final faceColor = switch (card.suit.group) {
      'R' => colorScheme.primary,
      'B' || _ => colorScheme.tertiary,
    };

    final highlight = latestAction is MoveCards &&
        latestAction.from is! Draw &&
        latestAction.to is! Draw &&
        latestAction.cards.contains(card);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(layout.cardPadding),
        width: layout.gridUnit.width,
        height: layout.gridUnit.height,
        decoration: highlight
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: faceColor,
              )
            : null,
        child: Material(
          borderRadius: BorderRadius.circular(8),
          elevation: elevation ?? 2,
          child: card.flipped
              ? const CardCover()
              : CardFace(
                  card: card,
                  foregroundColor: faceColor,
                ),
        ),
      ),
    );
  }
}

class CardFace extends StatelessWidget {
  const CardFace({
    super.key,
    required this.card,
    required this.foregroundColor,
  });

  final PlayCard card;

  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final layout = context.watch<GameLayout>();

    final spacingFactor = layout.gridUnit.width * 0.05;
    final labelSizingFactor = layout.gridUnit.width * 0.32;
    final iconSizingFactor = layout.gridUnit.width * 0.25;

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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  card.value.symbol,
                  style: TextStyle(
                    fontSize: labelSizingFactor,
                    fontWeight: FontWeight.bold,
                    color: foregroundColor,
                  ),
                ),
                SvgPicture.asset(
                  iconSvgPath,
                  width: labelSizingFactor * 0.9,
                  height: labelSizingFactor * 0.9,
                  colorFilter:
                      ColorFilter.mode(foregroundColor, BlendMode.srcIn),
                )
              ],
            ),
          ),
          Positioned(
            bottom: -(layout.gridUnit.height * 0.0),
            left: -(layout.gridUnit.width * 0.15),
            child: SvgPicture.asset(
              iconSvgPath,
              width: iconSizingFactor * 3,
              height: iconSizingFactor * 3,
              colorFilter: ColorFilter.mode(
                foregroundColor.withOpacity(0.15),
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
          width: layout.gridUnit.width * 0.1,
          color: cardColor.darken(0.07),
        ),
      ),
    );
  }
}
