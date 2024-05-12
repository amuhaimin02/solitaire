import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
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
                          Orientation.landscape => const Row(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                GameHUD(),
                                Flexible(child: GameTable()),
                              ],
                            ),
                          Orientation.portrait => const Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                GameHUD(),
                                Flexible(
                                  child: GameTable(),
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
}
