import 'package:flutter/material.dart';

class GameLayout {
  final Size gridUnit;
  final double cardPadding;
  final Offset maxStackGap;
  final Orientation orientation;

  final bool mirrorPileArrangement;

  GameLayout({
    required this.gridUnit,
    required this.cardPadding,
    required this.maxStackGap,
    required this.orientation,
    this.mirrorPileArrangement = false,
  });
}
