import 'package:flutter/material.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

part 'game_theme.tailor.dart';

const themeColorPalette = [
  Colors.red,
  Colors.pink,
  Colors.purple,
  Colors.deepPurple,
  Colors.indigo,
  Colors.blue,
  Colors.lightBlue,
  Colors.cyan,
  Colors.teal,
  Colors.green,
  Colors.lightGreen,
  Colors.lime,
  Colors.yellow,
  Colors.amber,
  Colors.orange,
  Colors.deepOrange,
];

@TailorMixin(themeGetter: ThemeGetter.onThemeData)
class GameTheme extends ThemeExtension<GameTheme> with _$GameThemeTailorMixin {
  const GameTheme({
    required this.tableBackgroundColor,
    required this.winningBackgroundColor,
    required this.hintHighlightColor,
    required this.lastMoveHighlightColor,
  });

  @override
  final Color tableBackgroundColor;

  @override
  final Color winningBackgroundColor;

  @override
  final Color hintHighlightColor;

  @override
  final Color lastMoveHighlightColor;

  factory GameTheme.from({
    required ColorScheme colorScheme,
    bool coloredBackground = false,
  }) {
    return GameTheme(
      tableBackgroundColor: coloredBackground
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainer,
      winningBackgroundColor: coloredBackground
          ? colorScheme.surfaceContainer
          : colorScheme.primaryContainer,
      hintHighlightColor: colorScheme.error,
      lastMoveHighlightColor: colorScheme.tertiary,
    );
  }
}

@TailorMixin(themeGetter: ThemeGetter.onThemeData)
class GameCardTheme extends ThemeExtension<GameCardTheme>
    with _$GameCardThemeTailorMixin {
  const GameCardTheme({
    required this.facePlainColor,
    required this.faceAccentColor,
    required this.labelPlainColor,
    required this.labelAccentColor,
    required this.backColor,
    this.unitSize = const Size(2.5, 3.5),
    this.margin = 0.05,
    this.stackGap = const Offset(0.3, 0.3),
    this.cornerRadius = 0.1,
    this.compressStack = false,
  });

  @override
  final Color facePlainColor;

  @override
  final Color faceAccentColor;

  @override
  final Color labelPlainColor;

  @override
  final Color labelAccentColor;

  @override
  final Color backColor;

  @override
  final Size unitSize;

  @override
  final double margin;

  @override
  final Offset stackGap;

  @override
  final double cornerRadius;

  @override
  final bool compressStack;

  factory GameCardTheme.from({
    required ColorScheme colorScheme,
    bool tintedCardFace = false,
    bool useClassicColors = false,
    bool contrastingFaceColors = false,
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

    if (contrastingFaceColors) {
      cardFacePlainColor = colorScheme.surfaceContainerLowest;
      cardFaceAccentColor = colorScheme.inverseSurface;
      cardLabelPlainColor = colorScheme.primary;
      cardLabelAccentColor = colorScheme.inversePrimary;
    }

    if (useClassicColors) {
      cardLabelPlainColor = Colors.grey.shade900;
      cardLabelAccentColor = Colors.red.shade600;
      cardFacePlainColor = Colors.grey.shade50;
      cardFaceAccentColor = Colors.grey.shade50;
    }

    return GameCardTheme(
      facePlainColor: cardFacePlainColor,
      faceAccentColor: cardFaceAccentColor,
      labelPlainColor: cardLabelPlainColor,
      labelAccentColor: cardLabelAccentColor,
      backColor: colorScheme.primary,
    );
  }
}
