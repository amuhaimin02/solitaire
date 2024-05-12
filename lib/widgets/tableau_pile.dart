import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../models/card.dart';
import '../models/game_state.dart';
import 'card_stack.dart';

class TableauPile extends StatelessWidget {
  const TableauPile({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int index = 0; index < gameState.tableauPile.length; index++)
          Expanded(
            child: TableauColumn(
              index: index,
            ),
          ),
      ],
    );
  }
}

class TableauColumn extends StatelessWidget {
  const TableauColumn({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    final tableau = gameState.tableauPile[index];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTap(context, index),
      child: CardStack(
        onCardTap: (card, idx) {
          final handled = _onTap(context, index);
          if (!handled) {
            _onCardTap(context, card, idx);
          }
        },
        direction: CardStackDirection.topDown,
        cards: tableau,
        markerIcon: MdiIcons.close,
      ),
    );
  }

  void _onCardTap(BuildContext context, PlayCard card, int cardIndex) {
    final gameState = context.read<GameState>();

    final tableauStack = gameState.tableauPile[index];
    final cardsToPick =
        tableauStack.getRange(cardIndex, tableauStack.length).toList();

    final handled = gameState.tryQuickPlace(cardsToPick, Tableau(index));

    if (handled) {
      HapticFeedback.mediumImpact();
    }
  }

  bool _onTap(BuildContext context, int index) {
    return false;
  }
}
