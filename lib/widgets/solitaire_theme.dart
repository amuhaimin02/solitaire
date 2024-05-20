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
    this.backgroundSecondaryColor,
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
    required this.cardCornerRadius,
  });

  final Color backgroundColor;

  final Color? backgroundSecondaryColor;

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

  final double cardCornerRadius;

  factory SolitaireThemeData.fromColorScheme({
    required ColorScheme colorScheme,
    required Size cardUnitSize,
    required double cardPadding,
    required Offset cardStackGap,
    required double cardCornerRadius,
    bool useGradientBackground = false,
  }) {
    return SolitaireThemeData(
      backgroundColor: colorScheme.primaryContainer,
      backgroundSecondaryColor:
          useGradientBackground ? colorScheme.tertiaryContainer : null,
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
      cardCornerRadius: cardCornerRadius,
    );
  }

  BoxDecoration generateBackgroundDecoration() {
    if (backgroundSecondaryColor != null) {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [backgroundSecondaryColor!, backgroundColor],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      );
    } else {
      return BoxDecoration(color: backgroundColor);
    }
  }
}
