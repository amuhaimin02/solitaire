import 'package:flutter/material.dart' hide Action;

import '../../../animations.dart';
import '../../../models/card.dart';
import '../../../models/game_theme.dart';
import '../../../widgets/flippable.dart';
import '../../../widgets/soft_shadow.dart';
import 'card_back.dart';
import 'card_face.dart';
import 'card_highlight.dart';

class CardView extends StatelessWidget {
  const CardView({
    super.key,
    required this.card,
    required this.size,
    this.elevation,
    this.hideFace = false,
    this.highlighted = false,
    this.selected = false,
    this.labelAlignment = Alignment.center,
  });

  final PlayCard card;

  final double? elevation;

  final bool hideFace;

  final bool highlighted;

  final bool selected;

  final Size size;

  final Alignment labelAlignment;

  @override
  Widget build(BuildContext context) {
    final cardTheme = Theme.of(context).gameCardTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Flippable(
      duration: cardMoveAnimation.duration,
      curve: cardMoveAnimation.curve,
      flipped: hideFace || card.flipped,
      front: Container(
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(size.shortestSide * cardTheme.cornerRadius),
          boxShadow: [SoftShadow(elevation ?? 2)],
        ),
        child: CardFace(
          card: card,
          size: size,
          labelAlignment: labelAlignment,
        ),
      ),
      back: Container(
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(size.shortestSide * cardTheme.cornerRadius),
          boxShadow: [SoftShadow(elevation ?? 2)],
        ),
        child: CardBack(size: size),
      ),
      builder: (context, child) {
        return BlinkingCardHighlight(
          active: selected,
          size: size,
          color: colorScheme.tertiary,
          child: ColorWheelCardHighlight(
            active: highlighted,
            size: size,
            child: Padding(
              padding: EdgeInsets.all(size.shortestSide * cardTheme.margin),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
