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
    required bool compressStack,
  }) = _CardThemeData;

  factory CardThemeData.fromColorScheme(
    ColorScheme colorScheme, {
    bool tintedCardFace = false,
    bool useClassicColors = false,
  }) {
    Color cardLabelPlainColor = colorScheme.onSurfaceVariant;
    Color cardLabelAccentColor = colorScheme.primary;
    Color cardFacePlainColor = colorScheme.surfaceContainerLowest;
    Color cardFaceAccentColor = colorScheme.surfaceContainerLowest;

    if (tintedCardFace && colorScheme.brightness == Brightness.dark) {
      cardLabelPlainColor = colorScheme.onSurfaceVariant;
      cardLabelAccentColor = colorScheme.onPrimaryContainer;
      cardFacePlainColor = colorScheme.surfaceContainerLowest;
      cardFaceAccentColor = colorScheme.onPrimary;
    }

    if (useClassicColors) {
      cardLabelPlainColor = Colors.grey.shade800;
      cardLabelAccentColor = Colors.red.shade600;
      cardFacePlainColor = Colors.grey.shade50;
      cardFaceAccentColor = Colors.grey.shade50;
    }

    return CardThemeData(
      facePlainColor: cardFacePlainColor,
      faceAccentColor: cardFaceAccentColor,
      labelPlainColor: cardLabelPlainColor,
      labelAccentColor: cardLabelAccentColor,
      coverColor: colorScheme.primary,
      unitSize: const Size(2.5, 3.5),
      margin: 0.05,
      coverBorderPadding: 0.02,
      stackGap: const Offset(0.3, 0.3),
      cornerRadius: 0.1,
      compressStack: false,
    );
  }
}
