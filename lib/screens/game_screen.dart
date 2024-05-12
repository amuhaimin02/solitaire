import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../models/game_layout.dart';
import '../models/game_state.dart';
import '../widgets/debug_hud.dart';
import '../widgets/game_hud.dart';
import '../widgets/game_table.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ChangeNotifierProvider(
      create: (_) => GameState(),
      builder: (context, child) {
        final isWinning =
            context.select<GameState, bool>((state) => state.isWinning);
        final showDebugPanel = context
            .select<GameState, bool>((state) => state.isDebugPanelShowing);

        return Scaffold(
          body: AnimatedContainer(
            duration: standardAnimationDuration,
            curve: standardAnimationCurve,
            color: isWinning
                ? colorScheme.errorContainer
                : colorScheme.surfaceVariant,
            child: OrientationBuilder(
              builder: (context, orientation) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: switch (orientation) {
                          Orientation.landscape => Row(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const GameHUD(),
                                Flexible(
                                  child: AspectRatio(
                                    aspectRatio: 1.5,
                                    child:
                                        _buildGameField(context, orientation),
                                  ),
                                ),
                              ],
                            ),
                          Orientation.portrait => Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const GameHUD(),
                                Flexible(
                                  child: AspectRatio(
                                    aspectRatio: 3 / 4,
                                    child:
                                        _buildGameField(context, orientation),
                                  ),
                                ),
                              ],
                            ),
                        },
                      ),
                    ),
                    if (showDebugPanel)
                      switch (orientation) {
                        Orientation.landscape => const Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: 200,
                              height: double.infinity,
                              child: DebugHUD(),
                            ),
                          ),
                        Orientation.portrait => const Align(
                            alignment: Alignment.bottomCenter,
                            child: SizedBox(
                              width: double.infinity,
                              height: 250,
                              child: DebugHUD(),
                            ),
                          ),
                      }
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameField(BuildContext context, Orientation orientation) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final aspectRatio = constraints.minHeight / constraints.minWidth;

        final landspaceMode = aspectRatio < 0.85;

        final double cardWidth, cardHeight;

        if (landspaceMode) {
          final tableWidth = constraints.minWidth;
          cardWidth = tableWidth / 10;
          cardHeight = cardWidth * (3.5 / 2.5);
        } else {
          final tableWidth = constraints.minWidth;
          cardWidth = tableWidth / 7;
          cardHeight = cardWidth * (3.5 / 2.5);
        }

        final layout = GameLayout(
          cardSize: Size(cardWidth, cardHeight),
          cardPadding: cardWidth * 0.06,
          verticalStackGap: cardHeight * 0.3,
          horizontalStackGap: cardWidth * 0.4,
          orientation:
              landspaceMode ? Orientation.landscape : Orientation.portrait,
          mirrorPileArrangement: false,
        );

        return ProxyProvider0<GameLayout>(
          update: (_, __) => layout,
          child: const GameTable(),
        );
      },
    );
  }
}
