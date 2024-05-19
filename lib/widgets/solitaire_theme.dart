import 'package:flutter/material.dart';

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
    required this.cardFaceColor,
    required this.cardLabelPlainColor,
    required this.cardLabelAccentColor,
    required this.cardCoverColor,
    required this.pileMarkerColor,
    required this.hintHighlightColor,
    required this.lastMoveHighlightColor,
    required this.cardUnitSize,
    required this.cardPadding,
    required this.cardStackGap,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final Color winningBackgroundColor;

  final Color cardFaceColor;
  final Color cardLabelPlainColor;
  final Color cardLabelAccentColor;
  final Color cardCoverColor;
  final Color pileMarkerColor;

  final Color hintHighlightColor;

  final Color lastMoveHighlightColor;
  final Size cardUnitSize;

  final double cardPadding;

  final Offset cardStackGap;

  factory SolitaireThemeData.fromColorScheme({
    required ColorScheme colorScheme,
    required Size cardUnitSize,
    required double cardPadding,
    required Offset cardStackGap,
  }) {
    return SolitaireThemeData(
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      winningBackgroundColor: colorScheme.surface,
      cardFaceColor: colorScheme.surfaceContainerLowest,
      cardLabelPlainColor: colorScheme.onSurface,
      cardLabelAccentColor: colorScheme.primary,
      cardCoverColor: colorScheme.primary,
      pileMarkerColor: colorScheme.onSurface,
      hintHighlightColor: colorScheme.error,
      lastMoveHighlightColor: colorScheme.secondary,
      cardUnitSize: cardUnitSize,
      cardPadding: cardPadding,
      cardStackGap: cardStackGap,
    );
  }
}
