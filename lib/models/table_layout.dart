import 'package:flutter/material.dart';

import 'direction.dart';
import 'pile.dart';

class TableLayout {
  final Size gridSize;
  final List<TableLayoutItem> items;

  TableLayout({
    required this.gridSize,
    required this.items,
  });
}

class TableLayoutItem {
  TableLayoutItem({
    required this.kind,
    required this.region,
    this.stackDirection = Direction.none,
    this.showCountIndicator = false,
    this.shiftStackOnPlace = false,
    this.numberOfCardsToShow,
  });

  final Pile kind;

  final Rect region;
  final Direction stackDirection;

  final bool showCountIndicator;

  final bool shiftStackOnPlace;

  final int? numberOfCardsToShow;
}

class TableLayoutOptions {
  TableLayoutOptions({required this.orientation, required this.mirror});
  final Orientation orientation;
  final bool mirror;
}
