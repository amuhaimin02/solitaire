import 'package:flutter/material.dart';

import 'action.dart';
import 'direction.dart';
import 'pile.dart';
import 'pile_action.dart';
import 'pile_check.dart';

class PileProperty {
  PileProperty({
    required this.kind,
    required this.layout,
    this.onStart,
    this.onSetup,
    this.pickable,
    this.placeable,
    this.ifEmpty,
    this.makeMove,
    this.onDrop,
    this.afterMove,
  });

  final Pile kind;

  final PileLayout layout;

  List<PileAction>? onStart;

  List<PileAction>? onSetup;

  List<PileCheck>? pickable;

  List<PileCheck>? placeable;

  List<PileAction>? ifEmpty;

  List<PileAction>? onDrop;

  List<PileAction>? afterMove;

  List<PileAction> Function(MoveIntent move)? makeMove;
}

class PileLayout {
  const PileLayout({
    required this.region,
    this.stackDirection,
    this.previewCards,
    this.showCount,
    this.shiftStack,
  });

  final LayoutProperty<Rect> region;

  final LayoutProperty<Direction>? stackDirection;

  final LayoutProperty<int>? previewCards;

  final LayoutProperty<bool>? showCount;

  final LayoutProperty<bool>? shiftStack;
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
