import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../models/pile.dart';
import 'solitaire_theme.dart';

class PileMarker extends StatelessWidget {
  const PileMarker({super.key, required this.pile, required this.size});

  final Pile pile;

  final Size size;

  @override
  Widget build(BuildContext context) {
    final theme = SolitaireTheme.of(context);

    final icon = switch (pile) {
      Draw() => MdiIcons.refresh,
      Discard() => MdiIcons.cardsPlaying,
      Foundation() => MdiIcons.alphaACircle,
      Tableau() => MdiIcons.alphaKBox,
      Reserve() => MdiIcons.star,
    };

    final borderOnly = theme.backgroundColor == Colors.black;

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(size.shortestSide * theme.cardTheme.margin),
      child: Container(
        decoration: BoxDecoration(
          color: borderOnly ? null : colorScheme.secondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(
              size.shortestSide * theme.cardTheme.cornerRadius),
          border: borderOnly
              ? Border.all(
                  color: colorScheme.secondary.withOpacity(0.2), width: 2)
              : null,
        ),
        child: Icon(
          icon,
          size: size.shortestSide * 0.5,
          color: colorScheme.secondary.withOpacity(0.2),
        ),
      ),
    );
  }
}
