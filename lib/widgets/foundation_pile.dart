import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import 'card_stack.dart';

class FoundationPile extends StatelessWidget {
  const FoundationPile({
    super.key,
    required this.index,
  });

  final int index;

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    final foundationPile = gameState.foundationPile;

    return GestureDetector(
      onTap: () => _onTap(context),
      child: CardStack(
        direction: CardStackDirection.bottomToFront,
        cards: foundationPile[index],
        markerIcon: MdiIcons.circleOutline,
      ),
    );
  }

  void _onTap(BuildContext context) {
    final gameState = context.read<GameState>();

    final foundationStack = gameState.foundationPile[index];

    if (foundationStack.isEmpty) {
      return;
    }

    final cardToPick = foundationStack.last;

    final handled = gameState.tryQuickPlace([cardToPick], Foundation(index));

    if (handled) {
      HapticFeedback.mediumImpact();
    }
  }
}
