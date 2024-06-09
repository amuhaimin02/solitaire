import 'package:flutter/material.dart';

import 'direction.dart';
import 'move_action.dart';
import 'move_check.dart';

class PileProperty {
  PileProperty({
    required this.layout,
    this.onStart,
    this.onSetup,
    required this.pickable,
    required this.placeable,
    this.canTap,
    this.onTap,
    this.afterMove,
    this.virtual = false,
  });

  final PileLayout layout;

  List<MoveAction>? onStart;

  List<MoveAction>? onSetup;

  List<MoveCheck> pickable;

  List<MoveCheck> placeable;

  List<MoveCheck>? canTap;

  List<MoveAction>? onTap;

  List<MoveAction>? afterMove;

  final bool virtual;
}

class PileLayout {
  const PileLayout({
    required this.region,
    this.stackDirection,
    this.previewCards,
    this.showCount,
    this.shiftStack,
    this.showMarker,
  });

  final LayoutProperty<Rect> region;

  final LayoutProperty<Direction>? stackDirection;

  final LayoutProperty<int>? previewCards;

  final LayoutProperty<bool>? showCount;

  final LayoutProperty<bool>? shiftStack;

  final LayoutProperty<bool>? showMarker;
}

class TableLayout {
  final Size portrait;

  final Size landscape;

  const TableLayout({
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

class LayoutProperty<T> {
  const LayoutProperty({
    this.portrait,
    this.landscape,
    this.others,
  });

  final T? portrait;
  final T? landscape;
  final T? others;

  const LayoutProperty.all(this.others)
      : portrait = null,
        landscape = null;

  T resolve(Orientation orientation) {
    return switch (orientation) {
      Orientation.portrait => _ensureNotNull(portrait ?? others),
      Orientation.landscape => _ensureNotNull(landscape ?? others),
    };
  }

  T _ensureNotNull(T? value) {
    if (value == null) {
      throw ArgumentError('Cannot resolve value as the result is null');
    }
    return value;
  }
}
