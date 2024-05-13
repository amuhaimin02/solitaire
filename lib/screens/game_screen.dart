import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../animations.dart';
import '../models/game_state.dart';
import '../utils/color_utils.dart';
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

        final backgroundColor = switch (colorScheme.brightness) {
          Brightness.light => colorScheme.surfaceVariant.lighten(0.2),
          Brightness.dark => colorScheme.surfaceVariant.darken(0.2),
        };

        return Scaffold(
          body: AnimatedContainer(
            duration: themeChangeAnimation.duration,
            curve: themeChangeAnimation.curve,
            color: isWinning ? colorScheme.errorContainer : backgroundColor,
            child: OrientationBuilder(
              builder: (context, orientation) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: switch (orientation) {
                        Orientation.landscape => const Padding(
                            padding: EdgeInsets.all(40.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                GameHUD(),
                                Flexible(child: GameTable()),
                              ],
                            ),
                          ),
                        Orientation.portrait => const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 32.0),
                                  child: GameHUD(),
                                ),
                                Flexible(
                                  child: GameTable(),
                                ),
                              ],
                            ),
                          ),
                      },
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
