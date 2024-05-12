import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../models/card.dart';
import '../models/game_layout.dart';
import '../models/game_state.dart';
import 'card_marker.dart';
import 'card_stack.dart';
import 'playing_card.dart';

class DrawPile extends StatelessWidget {
  const DrawPile({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    final drawPile = gameState.drawPile;

    return GestureDetector(
      onTap: () => _onTap(context),
      child: CardStack(
        direction: CardStackDirection.bottomToFront,
        cards: drawPile,
        markerIcon: MdiIcons.reload,
        showCardCount: true,
      ),
    );
  }

  void _onTap(BuildContext context) {
    final gameState = context.read<GameState>();

    if (gameState.drawPile.isNotEmpty) {
      gameState.pickFromDrawPile();
    } else {
      gameState.refreshDrawPile();
    }
  }
}
