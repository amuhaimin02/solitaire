import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_layout.dart';
import '../utils/widget_utils.dart';
import 'discard_pile.dart';
import 'draw_pile.dart';
import 'foundation_pile.dart';
import 'tableau_pile.dart';

class GameTable extends StatelessWidget {
  const GameTable({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = context.watch<GameLayout>();

    final cardSize = layout.cardSize;

    if (layout.orientation == Orientation.landscape) {
      return Center(
        child: AspectRatio(
          aspectRatio: 25 / 14,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const FoundationPile(
                arrangementAxis: Axis.vertical,
              ),
              SizedBox(width: cardSize.width / 2),
              const Expanded(child: TableauPile()),
              SizedBox(width: cardSize.width / 2),
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DiscardPile(
                    arrangementAxis: Axis.vertical,
                  ),
                  DrawPile(),
                ],
              )
            ].reverseIf(() => layout.mirrorPileArrangement),
          ),
        ),
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              const FoundationPile(
                arrangementAxis: Axis.horizontal,
              ),
              const DiscardPile(
                arrangementAxis: Axis.horizontal,
              ),
              const DrawPile(),
            ].reverseIf(() => layout.mirrorPileArrangement),
          ),
          SizedBox(height: cardSize.height / 4),
          const Expanded(
            child: TableauPile(),
          ),
        ],
      );
    }
  }
}
