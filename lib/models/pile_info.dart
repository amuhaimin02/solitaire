import 'package:flutter/material.dart';

import 'direction.dart';
import 'pile.dart';

class PileItem {
  PileItem({
    required this.kind,
    required this.layout,
  });

  final Pile kind;

  final PileLayout layout;
}

class PileLayout {
  const PileLayout({
    required this.portrait,
    required this.landscape,
    this.stackDirection = Direction.none,
    this.portraitStackDirection,
    this.landscapeStackDirection,
    this.previewCards,
    this.portraitShiftStack,
    this.landscapeShiftStack,
    this.showCount = false,
    this.shiftStack = false,
  });

  final Rect portrait;

  final Rect landscape;

  final Direction stackDirection;

  final Direction? portraitStackDirection;

  final Direction? landscapeStackDirection;

  final int? previewCards;

  final bool showCount;

  final bool shiftStack;

  final bool? portraitShiftStack;

  final bool? landscapeShiftStack;

  Rect resolvedRegion(Orientation orientation) {
    return switch (orientation) {
      Orientation.portrait => portrait,
      Orientation.landscape => landscape,
    };
  }

  Direction resolvedStackDirection(Orientation orientation) {
    return switch (orientation) {
      Orientation.portrait => portraitStackDirection ?? stackDirection,
      Orientation.landscape => landscapeStackDirection ?? stackDirection,
    };
  }

  bool resolveShiftStack(Orientation orientation) {
    return switch (orientation) {
      Orientation.portrait => portraitShiftStack ?? shiftStack,
      Orientation.landscape => landscapeShiftStack ?? shiftStack,
    };
  }
}

class TableLayoutNew {
  final Size portrait;

  final Size landscape;

  const TableLayoutNew({
    required this.portrait,
    required this.landscape,
  });

  Size resolve(Orientation orientation) {
    return switch (orientation) {
      Orientation.portrait => portrait,
      Orientation.landscape => landscape,
    };
  }
}
