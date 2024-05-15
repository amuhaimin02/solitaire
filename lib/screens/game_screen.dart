import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../animations.dart';
import '../models/game_state.dart';
import '../utils/colors.dart';
import '../widgets/background.dart';
import '../widgets/debug_hud.dart';
import '../widgets/control_pane.dart';
import '../widgets/game_table.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  Widget build(BuildContext context) {
    final showDebugPanel =
        context.select<GameState, bool>((state) => state.isDebugPanelShowing);

    return Scaffold(
      body: Background(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: OrientationBuilder(
          builder: (context, orientation) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.biggest.shortestSide < 600;

                final outerMargin = isMobile
                    ? const EdgeInsets.all(8)
                    : const EdgeInsets.all(40);

                return Stack(
                  children: [
                    Positioned.fill(
                      child: switch (orientation) {
                        Orientation.landscape => Padding(
                            padding: outerMargin,
                            child: const Row(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ControlPane(),
                                Flexible(child: GameTable()),
                              ],
                            ),
                          ),
                        Orientation.portrait => Padding(
                            padding: outerMargin,
                            child: const Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 32.0),
                                  child: ControlPane(),
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
            );
          },
        ),
      ),
    );
  }
}
