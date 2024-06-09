import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'direction.dart';
import 'move_action.dart';
import 'move_check.dart';

part 'pile_property.freezed.dart';

@freezed
class PileProperty with _$PileProperty {
  factory PileProperty({
    required PileLayout layout,
    List<MoveAction>? onStart,
    List<MoveAction>? onSetup,
    required List<MoveCheck> pickable,
    required List<MoveCheck> placeable,
    List<MoveCheck>? canTap,
    List<MoveAction>? onTap,
    List<MoveAction>? afterMove,
    @Default(false) bool virtual,
  }) = _PileProperty;
}

@freezed
class PileLayout with _$PileLayout {
  const factory PileLayout({
    required LayoutProperty<Rect> region,
    LayoutProperty<Direction>? stackDirection,
    LayoutProperty<int>? previewCards,
    LayoutProperty<bool>? showCount,
    LayoutProperty<bool>? shiftStack,
    LayoutProperty<bool>? showMarker,
  }) = _PileLayout;
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
