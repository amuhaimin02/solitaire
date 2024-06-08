import 'package:flutter/material.dart' hide Action;
import 'package:google_fonts/google_fonts.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../animations.dart';
import '../models/card.dart';
import '../utils/canvas.dart';
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
    this.labelAlignment = Alignment.center,
  });

  final PlayCard card;

  final double? elevation;

  final bool hideFace;

  final Color? highlightColor;

  final Size size;

  final Alignment labelAlignment;

  @override
  Widget build(BuildContext context) {
    final theme = SolitaireTheme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Flippable(
      duration: cardMoveAnimation.duration,
      curve: cardMoveAnimation.curve,
      flipped: hideFace || card.flipped,
      front: Material(
        borderRadius: BorderRadius.circular(
            size.shortestSide * theme.cardTheme.cornerRadius),
        elevation: elevation ?? 2,
        child: CardFace(
          card: card,
          size: size,
          labelAlignment: labelAlignment,
        ),
      ),
      back: Material(
        borderRadius: BorderRadius.circular(
            size.shortestSide * theme.cardTheme.cornerRadius),
        elevation: elevation ?? 2,
        child: CardBack(size: size),
      ),
      builder: (context, child) {
        return Stack(
          children: [
            CardHighlight(
              highlight: highlightColor != null,
              color: highlightColor ?? colorScheme.primary,
              size: size,
            ),
            Positioned.fill(
                child: Padding(
              padding:
                  EdgeInsets.all(size.shortestSide * theme.cardTheme.margin),
              child: child,
            )),
          ],
        );
      },
    );
  }
}

class CardHighlight extends StatelessWidget {
  const CardHighlight({
    super.key,
    required this.highlight,
    required this.color,
    required this.size,
  });

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
              (theme.cardTheme.cornerRadius + theme.cardTheme.margin)),
        ),
      ),
    );
  }
}

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
    final theme = SolitaireTheme.of(context);

    final iconPath = 'assets/${card.suit.name}.png';

    final Color backgroundColor, foregroundColor;
    switch (card.suit.color) {
      case SuitColor.black:
        backgroundColor = theme.cardTheme.facePlainColor;
        foregroundColor = theme.cardTheme.labelPlainColor;
      case SuitColor.red:
        backgroundColor = theme.cardTheme.faceAccentColor;
        foregroundColor = theme.cardTheme.labelAccentColor;
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

    if (labelAlignment != Alignment.center) {
      labelSize = cardShortestSide * 0.4;
      iconSize = cardShortestSide * 0.35;
    } else {
      labelSize = cardShortestSide * 0.5;
      iconSize = cardShortestSide * 0.6;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(
            size.shortestSide * theme.cardTheme.cornerRadius),
      ),
      child: ClipRRect(
        clipBehavior: Clip.hardEdge,
        borderRadius: BorderRadius.circular(
            size.shortestSide * theme.cardTheme.cornerRadius),
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
                  vertical: cardShortestSide * 0.08,
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

class CardBack extends StatelessWidget {
  const CardBack({super.key, required this.size});

  final Size size;

  @override
  Widget build(BuildContext context) {
    final theme = SolitaireTheme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(
          size.shortestSide * theme.cardTheme.cornerRadius),
      child: CustomPaint(
        painter: SimpleCardCover(
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

class SimpleCardCover extends CustomPainter {
  final Color color;
  final Color? secondaryColor;

  SimpleCardCover({
    super.repaint,
    required this.color,
    this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final drawArea = Offset.zero & size;
    final paint = Paint();

    if (secondaryColor != null) {
      paint.shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [color, secondaryColor!],
      ).createShader(drawArea);
    } else {
      paint.color = color;
    }
    canvas.drawRect(drawArea, paint);
  }

  @override
  bool shouldRepaint(covariant SimpleCardCover oldDelegate) {
    return color != oldDelegate.color;
  }
}

class FourTrianglesCardCover extends CustomPainter {
  final Color color;
  final Color secondaryColor;

  FourTrianglesCardCover({
    super.repaint,
    required this.color,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final drawArea = Offset.zero & size;
    final paint = Paint();

    paint.color = color;
    canvas.drawRect(drawArea, paint);

    final center = drawArea.center;
    final topLeft = drawArea.topLeft;
    final bottomLeft = drawArea.bottomLeft;
    final topRight = drawArea.topRight;
    final bottomRight = drawArea.bottomRight;

    paint.color = Color.lerp(color, secondaryColor, 0.33)!;
    drawShape(canvas, [center, topRight, bottomRight], paint);

    paint.color = Color.lerp(color, secondaryColor, 0.66)!;
    drawShape(canvas, [center, topLeft, bottomLeft], paint);

    paint.color = Color.lerp(color, secondaryColor, 1)!;
    drawShape(canvas, [center, bottomLeft, bottomRight], paint);
  }

  @override
  bool shouldRepaint(covariant FourTrianglesCardCover oldDelegate) {
    return color != oldDelegate.color;
  }
}

class FourBordersCardCover extends CustomPainter {
  final Color color;
  final Color secondaryColor;

  final double borderSizeRatio;
  FourBordersCardCover({
    super.repaint,
    required this.color,
    required this.secondaryColor,
    required this.borderSizeRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final drawArea = Offset.zero & size;
    final paint = Paint();

    final center = drawArea.center;
    final topLeft = drawArea.topLeft;
    final bottomLeft = drawArea.bottomLeft;
    final topRight = drawArea.topRight;
    final bottomRight = drawArea.bottomRight;

    final topLeftInner = Offset.lerp(topLeft, center, borderSizeRatio)!;
    final bottomLeftInner = Offset.lerp(bottomLeft, center, borderSizeRatio)!;
    final topRightInner = Offset.lerp(topRight, center, borderSizeRatio)!;
    final bottomRightInner = Offset.lerp(bottomRight, center, borderSizeRatio)!;

    paint.color = Color.lerp(color, secondaryColor, 0.5)!;
    canvas.drawRect(drawArea, paint);

    paint.color = Color.lerp(color, secondaryColor, 0)!;
    drawShape(canvas, [topLeft, topLeftInner, topRightInner, topRight], paint);

    paint.color = Color.lerp(color, secondaryColor, 0.25)!;
    drawShape(canvas, [topRight, topRightInner, bottomRightInner, bottomRight],
        paint);

    paint.color = Color.lerp(color, secondaryColor, 0.75)!;
    drawShape(
        canvas, [topLeft, topLeftInner, bottomLeftInner, bottomLeft], paint);

    paint.color = Color.lerp(color, secondaryColor, 1)!;
    drawShape(canvas,
        [bottomLeft, bottomLeftInner, bottomRightInner, bottomRight], paint);
  }

  @override
  bool shouldRepaint(covariant FourBordersCardCover oldDelegate) {
    return color != oldDelegate.color;
  }
}

class LayeredBorderCardCover extends CustomPainter {
  final Color color;
  final Color secondaryColor;

  LayeredBorderCardCover({
    super.repaint,
    required this.color,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final drawArea = Offset.zero & size;
    final paint = Paint();

    final center = drawArea.center;
    final topLeft = drawArea.topLeft;
    final bottomLeft = drawArea.bottomLeft;
    final topRight = drawArea.topRight;
    final bottomRight = drawArea.bottomRight;

    paint.color = Color.lerp(color, secondaryColor, 0)!;
    canvas.drawRect(drawArea, paint);

    for (final ratio in [1 / 3]) {
      final topLeftInner = Offset.lerp(topLeft, center, ratio)!;
      final bottomLeftInner = Offset.lerp(bottomLeft, center, ratio)!;
      final topRightInner = Offset.lerp(topRight, center, ratio)!;
      final bottomRightInner = Offset.lerp(bottomRight, center, ratio)!;

      paint.color = Color.lerp(color, secondaryColor, ratio)!;
      drawShape(
          canvas,
          [topLeftInner, topRightInner, bottomRightInner, bottomLeftInner],
          paint);
    }
  }

  @override
  bool shouldRepaint(covariant LayeredBorderCardCover oldDelegate) {
    return color != oldDelegate.color;
  }
}
