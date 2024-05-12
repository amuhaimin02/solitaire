import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_layout.dart';
import '../models/game_rules.dart';
import '../models/game_state.dart';
import 'discard_pile.dart';
import 'draw_pile.dart';
import 'foundation_pile.dart';
import 'tableau_pile.dart';

class GameTable extends StatelessWidget {
  const GameTable({super.key});

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final gameRules =
            context.select<GameState, GameRules>((s) => s.gameRules);

        const cardUnitSize = Size(2.5, 3.5);

        final options = TableLayoutOptions(
          orientation: orientation,
          mirror: false,
        );

        final tableLayout = gameRules.getLayout(options);

        return Center(
          child: AspectRatio(
            aspectRatio: (tableLayout.gridSize.width * cardUnitSize.width) /
                (tableLayout.gridSize.height * cardUnitSize.height),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final gridUnit = Size(
                  constraints.minWidth / tableLayout.gridSize.width,
                  constraints.minHeight / tableLayout.gridSize.height,
                );

                return ProxyProvider0<GameLayout>(
                  update: (context, obj) => GameLayout(
                    cardSize: gridUnit,
                    cardPadding: gridUnit.shortestSide * 0.04,
                    verticalStackGap: gridUnit.height * 0.3,
                    horizontalStackGap: gridUnit.width * 0.35,
                    orientation: orientation,
                  ),
                  child: Stack(
                    children: [
                      for (final item in tableLayout.items)
                        Positioned(
                          left: item.placement.dx * gridUnit.width,
                          top: item.placement.dy * gridUnit.height,
                          width: item.size.width * gridUnit.width,
                          height: item.size.height * gridUnit.height,
                          child: switch (item) {
                            DrawPileItem() => const DrawPile(),
                            DiscardPileItem() => DiscardPile(
                                arrangementAxis: switch (item.stackDirection) {
                                  PileStackDirection.topDown => Axis.vertical,
                                  PileStackDirection.rightToLeft =>
                                    Axis.horizontal,
                                  _ => throw ArgumentError(
                                      'Cannot use ${item.stackDirection} on DiscardPile')
                                },
                              ),
                            FoundationPileItem(index: var index) =>
                              FoundationPile(index: index),
                            TableauPileItem(index: var index) =>
                              TableauPile(index: index),
                          },
                        )
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
