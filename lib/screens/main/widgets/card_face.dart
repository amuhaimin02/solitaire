import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../animations.dart';
import '../../../models/card.dart';
import '../../../models/game_theme.dart';
import '../../../models/icons/card_suit_icons.dart';

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

  static final _suitIcons = {
    Suit.diamond: CardSuitIcons.diamonds,
    Suit.club: CardSuitIcons.clovers,
    Suit.heart: CardSuitIcons.hearts,
    Suit.spade: CardSuitIcons.spades,
  };

  @override
  Widget build(BuildContext context) {
    final cardShortestSide = size.shortestSide;
    final cardTheme = Theme.of(context).gameCardTheme;

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
      Alignment.centerLeft => Alignment.centerLeft,
      Alignment.centerRight => Alignment.centerRight,
      _ => throw ArgumentError('Label alignment is not valid: $labelAlignment'),
    };

    final double labelSize, iconSize;

    if (labelAlignment == Alignment.center) {
      labelSize = cardShortestSide * 0.5;
      iconSize = cardShortestSide * 0.75;
    } else {
      labelSize = cardShortestSide * 0.4;
      iconSize = cardShortestSide * 0.45;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius:
            BorderRadius.circular(size.shortestSide * cardTheme.cornerRadius),
      ),
      width: size.width,
      height: size.height,
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
                      style: GoogleFonts.getFont(
                        cardTheme.labelFontFamily,
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
                padding: EdgeInsets.only(
                  top: cardShortestSide * 0.05,
                ),
                child: TweenAnimationBuilder(
                  tween: Tween(begin: iconSize, end: iconSize),
                  duration: cardMoveAnimation.duration,
                  curve: cardMoveAnimation.curve,
                  builder: (context, size, child) {
                    return Icon(
                      _suitIcons[card.suit],
                      color: foregroundColor,
                      size: size,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
