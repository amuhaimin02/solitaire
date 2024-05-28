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
  });

  final PlayCard card;

  final double? elevation;

  final bool hideFace;

  final Color? highlightColor;

  final Size size;

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
            size.shortestSide * theme.cardStyle.cornerRadius),
        elevation: elevation ?? 2,
        child: CardFace(card: card, size: size),
      ),
      back: Material(
        borderRadius: BorderRadius.circular(
            size.shortestSide * theme.cardStyle.cornerRadius),
        elevation: elevation ?? 2,
        child: CardCover(size: size),
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
                  EdgeInsets.all(size.shortestSide * theme.cardStyle.margin),
              child: child,
            )),
          ],
        );
      },
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
    final labelSizingFactor = size.shortestSide * 0.36;
    final iconSizingFactor = size.shortestSide * 0.25;
    final theme = SolitaireTheme.of(context);

    final iconPath = 'assets/${card.suit.name}.png';

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
      child: ClipRRect(
        clipBehavior: Clip.hardEdge,
        borderRadius: BorderRadius.circular(
            size.shortestSide * theme.cardStyle.cornerRadius),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(
                  left: spacingFactor * 1.2,
                  right: spacingFactor * 1.6,
                  top: spacingFactor * 0.2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    card.rank.symbol,
                    style: GoogleFonts.dosis(
                      fontSize: labelSizingFactor,
                      height: 1.25,
                      color: foregroundColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // Icon(
                  //   suitIcons[card.suit],
                  //   size: labelSizingFactor * 0.9,
                  //   color: foregroundColor,
                  // ),
                  // SvgPicture.asset(
                  //   iconPath,
                  //   width: labelSizingFactor * 0.8,
                  //   height: labelSizingFactor * 0.8,
                  //   colorFilter:
                  //       ColorFilter.mode(foregroundColor, BlendMode.srcIn),
                  // ),
                  Image.asset(
                    iconPath,
                    width: labelSizingFactor * 0.8,
                    height: labelSizingFactor * 0.8,
                    color: foregroundColor,
                  )
                ],
              ),
            ),
            Positioned(
              bottom: -(size.height * 0.00),
              left: -(size.width * 0.10),
              // child: Icon(
              //   suitIcons[card.suit],
              //   size: iconSizingFactor * 3,
              //   color: foregroundColor.withOpacity(0.3),
              // ),
              child: Image.asset(
                iconPath,
                width: iconSizingFactor * 2.8,
                height: iconSizingFactor * 2.8,
                color: foregroundColor.withOpacity(0.3),
              ),
              // child: SvgPicture.asset(
              //   iconSvgPath,
              //   width: iconSizingFactor * 2.8,
              //   height: iconSizingFactor * 2.8,
              //   colorFilter: ColorFilter.mode(
              //     foregroundColor.withOpacity(0.3),
              //     BlendMode.srcIn,
              //   ),
              // ),
            )
          ],
        ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(
          size.shortestSide * theme.cardStyle.cornerRadius),
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
