import 'package:flutter/cupertino.dart';
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

const cardSizeRatio = Size(2.5, 3.5);

enum CardBackStyle { solid, gradient }

enum CardFaceStyle { accent, tinted, mixed, classic }

enum TableBackgroundStyle { simple, colored, gradient }

@TailorMixin(themeGetter: ThemeGetter.onThemeData)
class GameTheme extends ThemeExtension<GameTheme> with _$GameThemeTailorMixin {
  const GameTheme({
    required this.tableBackgroundColor,
    this.tableBackgroundSecondaryColor = Colors.transparent,
    required this.winningBackgroundColor,
    this.winningBackgroundSecondaryColor = Colors.transparent,
    this.tableBackgroundStyle = TableBackgroundStyle.simple,
  });

  @override
  final Color tableBackgroundColor;

  @override
  final Color tableBackgroundSecondaryColor;

  @override
  final Color winningBackgroundColor;

  @override
  final Color winningBackgroundSecondaryColor;

  @override
  final TableBackgroundStyle tableBackgroundStyle;

  factory GameTheme.from({
    required ColorScheme colorScheme,
    required TableBackgroundStyle tableBackgroundStyle,
  }) {
    switch (tableBackgroundStyle) {
      case TableBackgroundStyle.simple:
        return GameTheme(
          tableBackgroundStyle: tableBackgroundStyle,
          tableBackgroundColor: colorScheme.surfaceContainer,
          winningBackgroundColor: colorScheme.primaryContainer,
        );
      case TableBackgroundStyle.colored:
        return GameTheme(
          tableBackgroundStyle: tableBackgroundStyle,
          tableBackgroundColor: colorScheme.primaryContainer,
          winningBackgroundColor: colorScheme.surfaceContainer,
        );
      case TableBackgroundStyle.gradient:
        return GameTheme(
          tableBackgroundStyle: tableBackgroundStyle,
          tableBackgroundColor: colorScheme.primaryContainer,
          tableBackgroundSecondaryColor: colorScheme.tertiaryContainer,
          winningBackgroundColor: colorScheme.surfaceContainer,
          winningBackgroundSecondaryColor: colorScheme.primaryContainer,
        );
    }
  }

  BoxDecoration getTableBackgroundDecoration({bool isWinning = false}) {
    final Color startColor, endColor;

    switch (tableBackgroundStyle) {
      case TableBackgroundStyle.simple || TableBackgroundStyle.colored:
        if (isWinning) {
          startColor = endColor = winningBackgroundColor;
        } else {
          startColor = endColor = tableBackgroundColor;
        }
      case TableBackgroundStyle.gradient:
        if (isWinning) {
          startColor = winningBackgroundColor;
          endColor = winningBackgroundSecondaryColor;
        } else {
          startColor = tableBackgroundColor;
          endColor = tableBackgroundSecondaryColor;
        }
    }
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [startColor, endColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }
}

@TailorMixin(themeGetter: ThemeGetter.onThemeData)
class GameCardTheme extends ThemeExtension<GameCardTheme>
    with _$GameCardThemeTailorMixin {
  const GameCardTheme({
    required this.labelFontFamily,
    this.faceStyle = CardFaceStyle.accent,
    required this.facePlainColor,
    required this.faceAccentColor,
    required this.labelPlainColor,
    required this.labelAccentColor,
    required this.backColor,
    required this.backSecondaryColor,
    this.backStyle = CardBackStyle.solid,
    this.margin = 0.05,
    this.stackGap = const Offset(0.3, 0.3),
    this.cornerRadius = 0.1,
    this.compressStack = false,
  });

  @override
  final String labelFontFamily;

  @override
  final CardFaceStyle faceStyle;

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
  final Color backSecondaryColor;

  @override
  final CardBackStyle backStyle;

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
    required String labelFontFamily,
    required CardFaceStyle faceStyle,
    required CardBackStyle backStyle,
  }) {
    Color cardLabelPlainColor,
        cardLabelAccentColor,
        cardFacePlainColor,
        cardFaceAccentColor;

    switch (faceStyle) {
      case CardFaceStyle.accent:
        cardLabelPlainColor = colorScheme.onSurfaceVariant;
        cardLabelAccentColor = colorScheme.primary;
        cardFacePlainColor = colorScheme.surfaceContainerLowest;
        cardFaceAccentColor = colorScheme.surfaceContainerLowest;
      case CardFaceStyle.tinted:
        cardLabelPlainColor = colorScheme.onSurfaceVariant;
        cardLabelAccentColor = colorScheme.onPrimaryContainer;
        cardFacePlainColor = colorScheme.surfaceContainerLowest;
        cardFaceAccentColor = colorScheme.onPrimary;
      case CardFaceStyle.mixed:
        cardFacePlainColor = colorScheme.surfaceContainerLowest;
        cardFaceAccentColor = colorScheme.inverseSurface;
        cardLabelPlainColor = colorScheme.primary;
        cardLabelAccentColor = colorScheme.inversePrimary;
      case CardFaceStyle.classic:
        cardLabelPlainColor = Colors.grey.shade900;
        cardLabelAccentColor = Colors.red.shade600;
        cardFacePlainColor = Colors.grey.shade50;
        cardFaceAccentColor = Colors.grey.shade50;
    }

    return GameCardTheme(
      labelFontFamily: labelFontFamily,
      facePlainColor: cardFacePlainColor,
      faceAccentColor: cardFaceAccentColor,
      labelPlainColor: cardLabelPlainColor,
      labelAccentColor: cardLabelAccentColor,
      faceStyle: faceStyle,
      backStyle: backStyle,
      backColor: colorScheme.primary,
      backSecondaryColor: colorScheme.tertiary,
    );
  }
}
