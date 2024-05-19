import 'package:flutter/material.dart' hide Action;
import 'package:google_fonts/google_fonts.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../animations.dart';
import '../models/card.dart';
import '../utils/colors.dart';
import 'flippable.dart';
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

    final Color foregroundColor, backgroundColor, coverColor;

    switch (card.suit.color) {
      case SuitColor.black:
        foregroundColor = theme.cardLabelPlainColor;
        backgroundColor = theme.cardFaceColor;
      case SuitColor.red:
        foregroundColor = theme.cardLabelAccentColor;
        backgroundColor = theme.cardFaceColor;
    }
    coverColor = theme.cardCoverColor;

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        children: [
          CardHighlight(
            highlight: highlightColor != null,
            color: highlightColor ?? theme.foregroundColor,
          ),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(size.shortestSide * theme.cardPadding),
              child: Flippable(
                duration: cardMoveAnimation.duration,
                curve: cardMoveAnimation.curve,
                flipped: hideFace || card.flipped,
                front: Material(
                  borderRadius: BorderRadius.circular(8),
                  elevation: elevation ?? 2,
                  child: CardFace(
                    card: card,
                    size: size,
                    foregroundColor: foregroundColor,
                    backgroundColor: backgroundColor,
                  ),
                ),
                back: Material(
                  borderRadius: BorderRadius.circular(8),
                  elevation: elevation ?? 2,
                  child: CardCover(
                    color: coverColor,
                    size: size,
                  ),
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
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final PlayCard card;
  final Color foregroundColor;
  final Color backgroundColor;

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

    final iconSvgPath = 'assets/${card.suit.name}.svg';

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
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
              color: foregroundColor.withOpacity(0.36),
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
  const CardCover({super.key, required this.color, required this.size});

  final Color color;

  final Size size;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          width: size.shortestSide * 0.1,
          color: color.darken(0.15),
        ),
      ),
    );
  }
}

class CardHighlight extends StatelessWidget {
  const CardHighlight(
      {super.key, required this.highlight, required this.color});

  final Color color;

  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: cardMoveAnimation.duration,
      curve: highlight ? Curves.easeOutCirc : Curves.easeInCirc,
      scale: highlight ? 1 : 0.01,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
