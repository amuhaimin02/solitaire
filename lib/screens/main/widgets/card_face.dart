import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../animations.dart';
import '../../../models/card.dart';
import '../../../models/game_theme.dart';

class CardFace extends StatelessWidget {
  const CardFace({
    super.key,
    required this.card,
    required this.size,
    required this.labelAlignment,
  });

  final PlayCard card;

  final Size size;

  final Alignment labelAlignment;

  static final suitIcons = {
    Suit.diamond: MdiIcons.cardsDiamond,
    Suit.club: MdiIcons.cardsClub,
    Suit.heart: MdiIcons.cardsHeart,
    Suit.spade: MdiIcons.cardsSpade,
  };

  @override
  Widget build(BuildContext context) {
    final cardShortestSide = size.shortestSide;
    final cardTheme = Theme.of(context).gameCardTheme;

    final iconPath = 'assets/${card.suit.name}.png';

    final Color backgroundColor, foregroundColor;
    switch (card.suit.color) {
      case SuitColor.black:
        backgroundColor = cardTheme.facePlainColor;
        foregroundColor = cardTheme.labelPlainColor;
      case SuitColor.red:
        backgroundColor = cardTheme.faceAccentColor;
        foregroundColor = cardTheme.labelAccentColor;
    }

    final numberAlignment = switch (labelAlignment) {
      Alignment.center => Alignment.topLeft,
      Alignment.topCenter => Alignment.topLeft,
      Alignment.bottomCenter => Alignment.bottomLeft,
      Alignment.centerLeft => Alignment.topLeft,
      Alignment.centerRight => Alignment.topRight,
      _ => throw ArgumentError('Label alignment is not valid: $labelAlignment'),
    };

    final iconAlignment = switch (labelAlignment) {
      Alignment.center => Alignment.bottomRight,
      Alignment.topCenter => Alignment.topRight,
      Alignment.bottomCenter => Alignment.bottomRight,
      Alignment.centerLeft => Alignment.bottomLeft,
      Alignment.centerRight => Alignment.bottomRight,
      _ => throw ArgumentError('Label alignment is not valid: $labelAlignment'),
    };

    final double labelSize, iconSize;

    if (labelAlignment == Alignment.center) {
      labelSize = cardShortestSide * 0.5;
      iconSize = cardShortestSide * 0.6;
    } else {
      labelSize = cardShortestSide * 0.4;
      iconSize = cardShortestSide * 0.28;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius:
            BorderRadius.circular(size.shortestSide * cardTheme.cornerRadius),
      ),
      child: ClipRRect(
        clipBehavior: Clip.hardEdge,
        borderRadius:
            BorderRadius.circular(size.shortestSide * cardTheme.cornerRadius),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: cardMoveAnimation.duration,
              curve: cardMoveAnimation.curve,
              alignment: numberAlignment,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Align(
                  child: Padding(
                    padding: EdgeInsets.all(cardShortestSide * 0.07),
                    child: AnimatedDefaultTextStyle(
                      duration: cardMoveAnimation.duration,
                      curve: cardMoveAnimation.curve,
                      style: GoogleFonts.dosis(
                        fontSize: labelSize,
                        height: 1,
                        color: foregroundColor,
                        fontWeight: FontWeight.w600,
                      ),
                      child: Text(card.rank.symbol),
                    ),
                  ),
                ),
              ),
            ),
            AnimatedAlign(
              duration: cardMoveAnimation.duration,
              curve: cardMoveAnimation.curve,
              alignment: iconAlignment,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: cardShortestSide * 0.1,
                  horizontal: cardShortestSide * 0.06,
                ),
                child: AnimatedContainer(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage(iconPath),
                        colorFilter: ColorFilter.mode(
                            foregroundColor, BlendMode.srcATop)),
                  ),
                  duration: cardMoveAnimation.duration,
                  curve: cardMoveAnimation.curve,
                  width: iconSize,
                  height: iconSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
