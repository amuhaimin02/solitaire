import 'package:flutter/material.dart';

class GameLayout {
  final Size cardSize;
  final double cardPadding;
  final double verticalStackGap;

  final double horizontalStackGap;
  final Orientation orientation;

  final bool mirrorPileArrangement;

  GameLayout({
    required this.cardSize,
    required this.cardPadding,
    required this.verticalStackGap,
    required this.horizontalStackGap,
    required this.orientation,
    this.mirrorPileArrangement = false,
  });
}
