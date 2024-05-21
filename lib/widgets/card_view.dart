import 'package:flutter/material.dart' hide Action;
import 'package:google_fonts/google_fonts.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../animations.dart';
import '../models/card.dart';
import '../utils/colors.dart';
import 'flippable.dart';
import 'soft_shadow.dart';
import 'solitaire_theme.dart';

class CardView extends StatelessWidget {
  const CardView({
    super.key,
    required this.card,
    required this.size,
    this.elevation,
    this.hideFace = false,
    this.highlightColor,
  });

  final PlayCard card;

  final double? elevation;

  final bool hideFace;

  final Color? highlightColor;

  final Size size;

  @override
  Widget build(BuildContext context) {
    final theme = SolitaireTheme.of(context);

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        children: [
          CardHighlight(
            highlight: highlightColor != null,
            color: highlightColor ?? theme.foregroundColor,
            size: size,
          ),
          Positioned.fill(
            child: Padding(
              padding:
                  EdgeInsets.all(size.shortestSide * theme.cardStyle.margin),
              child: Flippable(
                duration: cardMoveAnimation.duration,
                curve: cardMoveAnimation.curve,
                flipped: hideFace || card.flipped,
                front: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                        size.shortestSide * theme.cardStyle.cornerRadius),
                    boxShadow: [SoftShadow(elevation ?? 2)],
                  ),
                  child: CardFace(card: card, size: size),
                ),
                back: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                        size.shortestSide * theme.cardStyle.cornerRadius),
                    boxShadow: [SoftShadow(elevation ?? 2)],
                  ),
                  child: CardCover(size: size),
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
    required this.size,
  });

  final PlayCard card;

  final Size size;

  static final suitIcons = {
    Suit.diamond: MdiIcons.cardsDiamond,
    Suit.club: MdiIcons.cardsClub,
    Suit.heart: MdiIcons.cardsHeart,
    Suit.spade: MdiIcons.cardsSpade,
  };

  @override
  Widget build(BuildContext context) {
    final spacingFactor = size.shortestSide * 0.05;
    final labelSizingFactor = size.shortestSide * 0.32;
    final iconSizingFactor = size.shortestSide * 0.25;
    final theme = SolitaireTheme.of(context);

    final iconSvgPath = 'assets/${card.suit.name}.svg';

    final Color backgroundColor, foregroundColor;
    switch (card.suit.color) {
      case SuitColor.black:
        backgroundColor = theme.cardStyle.facePlainColor;
        foregroundColor = theme.cardStyle.labelPlainColor;
      case SuitColor.red:
        backgroundColor = theme.cardStyle.faceAccentColor;
        foregroundColor = theme.cardStyle.labelAccentColor;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(
            size.shortestSide * theme.cardStyle.cornerRadius),
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
                    color: foregroundColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  suitIcons[card.suit],
                  size: labelSizingFactor * 0.9,
                  color: foregroundColor,
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
            bottom: -(size.height * 0.0),
            left: -(size.width * 0.15),
            child: Icon(
              suitIcons[card.suit],
              size: iconSizingFactor * 3,
              color: foregroundColor.withOpacity(0.4),
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
  const CardCover({super.key, required this.size});

  final Size size;

  @override
  Widget build(BuildContext context) {
    final theme = SolitaireTheme.of(context);
    final borderPadding =
        size.shortestSide * theme.cardStyle.coverBorderPadding;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        // color: theme.cardStyle.coverColor,
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(
            size.shortestSide * theme.cardStyle.cornerRadius),
      ),
      // child: Container(
      //   decoration: BoxDecoration(
      //     borderRadius: BorderRadius.circular(
      //         size.shortestSide * theme.cardStyle.cornerRadius),
      //     border: Border.all(
      //       color: colorScheme.shadow.withOpacity(0.1),
      //       width: borderPadding,
      //     ),
      //   ),
      // ),
    );
  }
}

class CardHighlight extends StatelessWidget {
  const CardHighlight(
      {super.key,
      required this.highlight,
      required this.color,
      required this.size});

  final Color color;

  final bool highlight;

  final Size size;

  @override
  Widget build(BuildContext context) {
    final theme = SolitaireTheme.of(context);
    return AnimatedScale(
      duration: cardMoveAnimation.duration,
      curve: highlight ? Curves.easeOutCirc : Curves.easeInCirc,
      scale: highlight ? 1 : 0.01,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size.shortestSide *
              (theme.cardStyle.cornerRadius + theme.cardStyle.margin)),
        ),
      ),
    );
  }
}
