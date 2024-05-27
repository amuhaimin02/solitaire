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
    required this.appBackgroundColor,
    required this.tableBackgroundColor,
    required this.winningBackgroundColor,
    required this.pileMarkerColor,
    required this.hintHighlightColor,
    required this.lastMoveHighlightColor,
    required this.cardStyle,
  });

  final Color appBackgroundColor;
  final Color tableBackgroundColor;

  final Color winningBackgroundColor;

  final Color pileMarkerColor;

  final Color hintHighlightColor;

  final Color lastMoveHighlightColor;

  final SolitaireCardStyle cardStyle;

  factory SolitaireThemeData.fromColorScheme({
    required ColorScheme colorScheme,
    required SolitaireCardStyle cardStyle,
    bool amoledDarkTheme = false,
    bool coloredBackground = false,
  }) {
    final Color appBackgroundColor,
        tableBackgroundColor,
        winningBackgroundColor;

    if (amoledDarkTheme && colorScheme.brightness == Brightness.dark) {
      appBackgroundColor = tableBackgroundColor = Colors.black;
      winningBackgroundColor = colorScheme.surfaceContainerHighest;
    } else if (coloredBackground) {
      appBackgroundColor = colorScheme.surface;
      tableBackgroundColor = colorScheme.primaryContainer;
      winningBackgroundColor = colorScheme.surfaceContainerHighest;
    } else {
      appBackgroundColor = colorScheme.surface;
      tableBackgroundColor = colorScheme.surfaceContainerHighest;
      winningBackgroundColor = colorScheme.primaryContainer;
    }

    return SolitaireThemeData(
      appBackgroundColor: appBackgroundColor,
      tableBackgroundColor: tableBackgroundColor,
      winningBackgroundColor: winningBackgroundColor,
      pileMarkerColor: colorScheme.onSurface,
      hintHighlightColor: colorScheme.error,
      lastMoveHighlightColor: colorScheme.tertiary,
      cardStyle: cardStyle,
    );
  }
}

class SolitaireCardStyle {
  final Color facePlainColor;

  final Color faceAccentColor;
  final Color labelPlainColor;
  final Color labelAccentColor;
  final Color coverColor;
  final Size unitSize;

  final double margin;

  final double coverBorderPadding;

  final Offset stackGap;

  final double cornerRadius;

  SolitaireCardStyle({
    required this.facePlainColor,
    required this.faceAccentColor,
    required this.labelPlainColor,
    required this.labelAccentColor,
    required this.coverColor,
    required this.unitSize,
    required this.margin,
    required this.coverBorderPadding,
    required this.stackGap,
    required this.cornerRadius,
  });

  factory SolitaireCardStyle.fromColorScheme(
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

    return SolitaireCardStyle(
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
