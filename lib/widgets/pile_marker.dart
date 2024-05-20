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
      Foundation() => MdiIcons.circleOutline,
      Tableau() => MdiIcons.close,
    };

    return Container(
      padding: EdgeInsets.all(size.shortestSide * theme.cardPadding),
      child: Container(
        decoration: BoxDecoration(
          color: theme.pileMarkerColor.withOpacity(0.1),
          borderRadius:
              BorderRadius.circular(size.shortestSide * theme.cardCornerRadius),
        ),
        child: Icon(
          icon,
          size: size.shortestSide * 0.5,
          color: theme.pileMarkerColor.withOpacity(0.3),
        ),
      ),
    );
  }
}
