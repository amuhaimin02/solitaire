import 'package:flutter/material.dart' hide Action;
import 'package:google_fonts/google_fonts.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../animations.dart';
import '../models/card.dart';
import '../models/game_layout.dart';
import '../models/game_state.dart';
import '../models/pile.dart';
import '../providers/settings.dart';
import '../utils/colors.dart';
import 'flippable.dart';

class CardView extends StatelessWidget {
  const CardView({
    super.key,
    required this.card,
    required this.pile,
    this.elevation,
    this.hideFace = false,
  });

  final PlayCard card;

  final Pile pile;

  final double? elevation;

  final bool hideFace;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final layout = context.watch<GameLayout>();
    final latestAction =
        context.select<GameState, Action?>((s) => s.latestAction);

    final showMoveHighlight =
        context.select<Settings, bool>((s) => s.showMoveHighlight());

    return SizedBox(
      width: layout.gridUnit.width,
      height: layout.gridUnit.height,
      child: Stack(
        children: [
          if (showMoveHighlight)
            CardHighlight(
              highlight: latestAction is Move &&
                  latestAction.from is! Draw &&
                  latestAction.to is! Draw &&
                  latestAction.cards.contains(card),
            ),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(layout.cardPadding),
              child: Flippable(
                duration: cardMoveAnimation.duration,
                curve: cardMoveAnimation.curve,
                flipped: hideFace || card.flipped,
                front: Material(
                  borderRadius: BorderRadius.circular(8),
                  elevation: elevation ?? 2,
                  child: CardFace(
                    card: card,
                  ),
                ),
                back: Material(
                  borderRadius: BorderRadius.circular(8),
                  elevation: elevation ?? 2,
                  child: const CardCover(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CardFace extends StatelessWidget {
  const CardFace({
    super.key,
    required this.card,
  });

  final PlayCard card;

  static final suitIcons = {
    Suit.diamond: MdiIcons.cardsDiamond,
    Suit.club: MdiIcons.cardsClub,
    Suit.heart: MdiIcons.cardsHeart,
    Suit.spade: MdiIcons.cardsSpade,
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final layout = context.watch<GameLayout>();

    final spacingFactor = layout.gridUnit.width * 0.05;
    final labelSizingFactor = layout.gridUnit.width * 0.32;
    final iconSizingFactor = layout.gridUnit.width * 0.25;

    final iconSvgPath = 'assets/${card.suit.name}.svg';

    final cardColor = switch (card.suit.color) {
      SuitColor.red => colorScheme.tertiary,
      SuitColor.black => colorScheme.primary,
    };

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
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
                  style: GoogleFonts.dosis(
                    fontSize: labelSizingFactor,
                    color: cardColor,
                  ),
                ),
                Icon(
                  suitIcons[card.suit],
                  size: labelSizingFactor * 0.9,
                  color: cardColor,
                ),
                // SvgPicture.asset(
                //   iconSvgPath,
                //   width: labelSizingFactor * 0.9,
                //   height: labelSizingFactor * 0.9,
                //   colorFilter: ColorFilter.mode(cardColor, BlendMode.srcIn),
                // )
              ],
            ),
          ),
          Positioned(
            bottom: -(layout.gridUnit.height * 0.0),
            left: -(layout.gridUnit.width * 0.15),
            child: Icon(
              suitIcons[card.suit],
              size: iconSizingFactor * 3,
              color: cardColor.withOpacity(0.2),
            ),
            // child: SvgPicture.asset(
            //   iconSvgPath,
            //   width: iconSizingFactor * 3,
            //   height: iconSizingFactor * 3,
            //   colorFilter: ColorFilter.mode(
            //     cardColor.withOpacity(0.2),
            //     BlendMode.srcIn,
            //   ),
            // ),
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

class CardHighlight extends StatelessWidget {
  const CardHighlight({super.key, required this.highlight});

  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedScale(
      duration: cardMoveAnimation.duration,
      curve: highlight ? Curves.easeOutCirc : Curves.easeInCirc,
      scale: highlight ? 1 : 0.01,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.secondary,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
