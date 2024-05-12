import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../models/card.dart';
import '../models/game_state.dart';
import 'card_marker.dart';
import 'card_stack.dart';
import 'playing_card.dart';

class FoundationPile extends StatelessWidget {
  const FoundationPile({super.key, required this.arrangementAxis});

  final Axis arrangementAxis;

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    final foundationPile = gameState.foundationPile;

    final children = [
      for (int i = 0; i < foundationPile.length; i++)
        GestureDetector(
          onTap: () => _onTap(context, i),
          child: CardStack(
            direction: CardStackDirection.bottomToFront,
            cards: foundationPile[i],
            markerIcon: MdiIcons.circleOutline,
          ),
        ),
    ];

    return switch (arrangementAxis) {
      Axis.vertical =>
        Column(mainAxisSize: MainAxisSize.min, children: children),
      Axis.horizontal => Row(
          mainAxisSize: MainAxisSize.min, children: children.reversed.toList()),
    };
  }

  void _onTap(BuildContext context, int index) {
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

    // if (gameState.isCardInHand()) {
    //   final pickedCardLocation = gameState.cardsInHand!.location;
    //   if (pickedCardLocation is Foundation &&
    //       pickedCardLocation.index == index) {
    //     final handled = gameState.tryQuickPlace();
    //     if (!handled) {
    //       gameState.releaseCardsFromHand();
    //       return;
    //     }
    //   }
    // }
    //
    // if (gameState.isCardInHand()) {
    //   gameState.placeCards(Foundation(index));
    // } else {
    //   final foundationStack = gameState.foundationPile[index];
    //   if (foundationStack.isNotEmpty) {
    //     gameState.holdCards([foundationStack.last], Foundation(index));
    //   }
    // }
  }
}
