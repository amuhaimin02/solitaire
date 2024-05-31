import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'theme.freezed.dart';

@freezed
class TableThemeData with _$TableThemeData {
  factory TableThemeData({
    required Color backgroundColor,
    required Color winningBackgroundColor,
    required Color hintHighlightColor,
    required Color lastMoveHighlightColor,
    required CardThemeData cardTheme,
  }) = _TableThemeData;

  factory TableThemeData.fromColorScheme({
    required ColorScheme colorScheme,
    required CardThemeData cardTheme,
    bool coloredBackground = false,
  }) {
    final Color backgroundColor;
    final Color winningBackgroundColor;

    if (coloredBackground) {
      backgroundColor = colorScheme.primaryContainer;
      winningBackgroundColor = colorScheme.surfaceContainer;
    } else {
      backgroundColor = colorScheme.surfaceContainer;
      winningBackgroundColor = colorScheme.primaryContainer;
    }

    return TableThemeData(
      backgroundColor: backgroundColor,
      winningBackgroundColor: winningBackgroundColor,
      hintHighlightColor: colorScheme.error,
      lastMoveHighlightColor: colorScheme.tertiary,
      cardTheme: cardTheme,
    );
  }
}

@freezed
class CardThemeData with _$CardThemeData {
  factory CardThemeData({
    required Color facePlainColor,
    required Color faceAccentColor,
    required Color labelPlainColor,
    required Color labelAccentColor,
    required Color coverColor,
    required Size unitSize,
    required double margin,
    required double coverBorderPadding,
    required Offset stackGap,
    required double cornerRadius,
  }) = _CardThemeData;

  factory CardThemeData.fromColorScheme(
    ColorScheme colorScheme, {
    bool tintedCardFace = false,
  }) {
    final Color cardFacePlainColor, cardFaceAccentColor;
    final Color cardLabelPlainColor, cardLabelAccentColor;

    if (tintedCardFace) {
      if (colorScheme.brightness == Brightness.dark) {
        cardLabelPlainColor = colorScheme.onSurface;
        cardLabelAccentColor = colorScheme.onPrimaryContainer;
        cardFacePlainColor = colorScheme.surfaceContainer;
        cardFaceAccentColor = colorScheme.onPrimary;
      } else {
        cardLabelPlainColor = colorScheme.onSurface;
        cardLabelAccentColor = colorScheme.onPrimaryContainer;
        cardFacePlainColor = colorScheme.surfaceContainerLowest;
        cardFaceAccentColor = colorScheme.primaryContainer;
      }
    } else {
      cardLabelPlainColor = colorScheme.onSurface;
      cardLabelAccentColor = colorScheme.primary;
      cardFacePlainColor = colorScheme.surfaceContainerLowest;
      cardFaceAccentColor = colorScheme.surfaceContainerLowest;
    }

    return CardThemeData(
      facePlainColor: cardFacePlainColor,
      faceAccentColor: cardFaceAccentColor,
      labelPlainColor: cardLabelPlainColor,
      labelAccentColor: cardLabelAccentColor,
      coverColor: colorScheme.primary,
      unitSize: const Size(2.5, 3.5),
      margin: 0.06,
      coverBorderPadding: 0.02,
      stackGap: const Offset(0.3, 0.3),
      cornerRadius: 0.1,
    );
  }
}
