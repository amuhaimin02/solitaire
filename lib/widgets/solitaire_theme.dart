import 'package:flutter/material.dart';

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

class SolitaireTheme extends StatelessWidget {
  const SolitaireTheme({super.key, required this.child, required this.data});

  final Widget child;

  final SolitaireThemeData data;

  static SolitaireThemeData? maybeOf(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<_InheritedTheme>();
    return inherited?.theme.data;
  }

  static SolitaireThemeData of(BuildContext context) {
    final data = maybeOf(context);
    assert(data != null, 'No SolitaireTheme found in context');
    return data!;
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedTheme(
      theme: this,
      child: child,
    );
  }
}

class _InheritedTheme extends InheritedWidget {
  const _InheritedTheme({required super.child, required this.theme});

  final SolitaireTheme theme;

  @override
  bool updateShouldNotify(covariant _InheritedTheme oldWidget) {
    return theme != oldWidget.theme;
  }
}

@immutable
class SolitaireThemeData {
  const SolitaireThemeData({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.winningBackgroundColor,
    required this.cardFacePlainColor,
    required this.cardFaceAccentColor,
    required this.cardLabelPlainColor,
    required this.cardLabelAccentColor,
    required this.cardCoverColor,
    required this.cardCoverBorderColor,
    required this.pileMarkerColor,
    required this.hintHighlightColor,
    required this.lastMoveHighlightColor,
    required this.cardUnitSize,
    required this.cardPadding,
    required this.cardCoverBorderPadding,
    required this.cardStackGap,
    required this.cardCornerRadius,
  });

  final Color backgroundColor;

  final Color foregroundColor;
  final Color winningBackgroundColor;

  final Color cardFacePlainColor;

  final Color cardFaceAccentColor;
  final Color cardLabelPlainColor;
  final Color cardLabelAccentColor;
  final Color cardCoverColor;

  final Color cardCoverBorderColor;
  final Color pileMarkerColor;

  final Color hintHighlightColor;

  final Color lastMoveHighlightColor;
  final Size cardUnitSize;

  final double cardPadding;

  final double cardCoverBorderPadding;

  final Offset cardStackGap;

  final double cardCornerRadius;

  factory SolitaireThemeData.fromColorScheme({
    required ColorScheme colorScheme,
    required Size cardUnitSize,
    required double cardPadding,
    required double cardCoverBorderPadding,
    required Offset cardStackGap,
    required double cardCornerRadius,
    bool amoledDarkTheme = false,
  }) {
    final Color cardFacePlainColor, cardFaceAccentColor;
    final Color cardLabelPlainColor, cardLabelAccentColor;
    final Color backgroundColor;

    cardLabelPlainColor = colorScheme.onSurface;
    cardLabelAccentColor = colorScheme.primary;

    if (amoledDarkTheme && colorScheme.brightness == Brightness.dark) {
      backgroundColor = Colors.black;
      cardFacePlainColor = colorScheme.surfaceContainer;
      cardFaceAccentColor = colorScheme.surfaceContainer;
    } else {
      backgroundColor = colorScheme.surfaceContainer;
      cardFacePlainColor = colorScheme.surfaceContainerLowest;
      cardFaceAccentColor = colorScheme.surfaceContainerLowest;
    }

    return SolitaireThemeData(
      backgroundColor: backgroundColor,
      foregroundColor: colorScheme.onPrimaryContainer,
      winningBackgroundColor: colorScheme.surface,
      cardFacePlainColor: cardFacePlainColor,
      cardFaceAccentColor: cardFaceAccentColor,
      cardLabelPlainColor: cardLabelPlainColor,
      cardLabelAccentColor: cardLabelAccentColor,
      cardCoverColor: colorScheme.primary,
      cardCoverBorderColor: colorScheme.onPrimaryFixed.withOpacity(0.2),
      pileMarkerColor: colorScheme.onSurface,
      hintHighlightColor: colorScheme.error,
      lastMoveHighlightColor: colorScheme.secondary,
      cardUnitSize: cardUnitSize,
      cardPadding: cardPadding,
      cardCoverBorderPadding: cardCoverBorderPadding,
      cardStackGap: cardStackGap,
      cardCornerRadius: cardCornerRadius,
    );
  }
}
