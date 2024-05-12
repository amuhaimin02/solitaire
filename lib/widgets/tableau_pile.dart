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
        for (int index = 0; index < gameState.tableaux.length; index++)
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

    final tableau = gameState.tableaux[index];

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

    // if (!gameState.isCardInHand()) {
    //   final tableauStack = gameState.tableaux[index];
    //   if (tableauStack.isNotEmpty) {
    //     final cardsToPick = tableauStack.slice(cardIndex);
    //     gameState.holdCards(cardsToPick, Tableau(index));
    //   }
    // }
    final tableauStack = gameState.tableaux[index];
    final cardsToPick = tableauStack.slice(cardIndex);

    final handled = gameState.tryQuickPlace(cardsToPick, Tableau(index));

    if (handled) {
      HapticFeedback.mediumImpact();
    }
  }

  bool _onTap(BuildContext context, int index) {
    // final gameState = context.read<GameState>();
    //
    // if (gameState.isCardInHand()) {
    //   final pickedCardLocation = gameState.cardsInHand!.location;
    //
    //   if (pickedCardLocation is Tableau && pickedCardLocation.index == index) {
    //     final handled = gameState.tryQuickPlace();
    //     if (!handled) {
    //       gameState.releaseCardsFromHand();
    //       return true;
    //     }
    //   }
    //
    //   gameState.placeCards(Tableau(index));
    //   return true;
    // }
    //
    // return false;
    return false;
  }
}
