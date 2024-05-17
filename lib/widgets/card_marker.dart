import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../models/game_layout.dart';
import '../models/pile.dart';

class PileMarker extends StatelessWidget {
  const PileMarker({super.key, required this.pile});

  final Pile pile;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final layout = context.watch<GameLayout>();

    final icon = switch (pile) {
      Draw() => MdiIcons.refresh,
      Discard() => MdiIcons.cardsPlaying,
      Foundation() => MdiIcons.circleOutline,
      Tableau() => MdiIcons.close,
    };

    return Container(
      padding: EdgeInsets.all(layout.cardPadding),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: layout.gridUnit.width * 0.5,
          color: colorScheme.onSurface.withOpacity(0.3),
        ),
      ),
    );
  }
}
