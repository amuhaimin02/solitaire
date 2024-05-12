import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../models/game_layout.dart';
import '../models/game_state.dart';
import 'card_stack.dart';

class DiscardPile extends StatelessWidget {
  const DiscardPile({super.key, required this.arrangementAxis});

  final Axis arrangementAxis;

  static const maxCardsToShow = 3;

  @override
  Widget build(BuildContext context) {
    final layout = context.watch<GameLayout>();
    final gameState = context.watch<GameState>();

    final discardPile = gameState.discardPile;

    Widget wrapWithContainer(Widget child) {
      return switch (arrangementAxis) {
        Axis.horizontal => SizedBox(
            width: layout.cardSize.width * 2,
            height: layout.cardSize.height,
            child: child,
          ),
        Axis.vertical => SizedBox(
            width: layout.cardSize.width,
            height: layout.cardSize.height * 2,
            child: child,
          ),
      };
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTap(context),
      child: wrapWithContainer(
        CardStack(
          direction: switch (arrangementAxis) {
            Axis.horizontal => CardStackDirection.rightToLeft,
            Axis.vertical => CardStackDirection.topDown,
          },
          cards: discardPile,
          markerIcon: MdiIcons.cardsPlaying,
          maxCardsToShow: 3,
          shiftCardsOnStack: arrangementAxis == Axis.horizontal,
        ),
      ),
    );
  }

  void _onTap(BuildContext context) {
    final gameState = context.read<GameState>();

    final discardPile = gameState.discardPile;

    if (discardPile.isEmpty) {
      return;
    }

    final cardToPick = discardPile.last;
    final handled = gameState.tryQuickPlace([cardToPick], Discard());

    if (handled) {
      HapticFeedback.mediumImpact();
    }
  }
}
