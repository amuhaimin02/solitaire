import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../providers/settings.dart';
import '../widgets/background.dart';
import '../widgets/control_pane.dart';
import '../widgets/debug_control_pane.dart';
import '../widgets/debug_hud.dart';
import '../widgets/game_table.dart';
import '../widgets/status_pane.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isWinning = context.select<GameState, bool>((s) => s.isWinning);

    return Scaffold(
      body: RippleBackground(
        color: isWinning
            ? colorScheme.tertiaryContainer
            : colorScheme.primaryContainer,
        child: SafeArea(
          child: OrientationBuilder(
            builder: (context, orientation) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.biggest.shortestSide < 600;

                  final outerMargin = isMobile
                      ? const EdgeInsets.all(8)
                      : const EdgeInsets.all(40);

                  final divider = SizedBox(
                    width: 48,
                    child: Divider(
                      height: 24,
                      color: colorScheme.onPrimaryContainer.withOpacity(0.3),
                    ),
                  );

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: switch (orientation) {
                          Orientation.landscape => Padding(
                              padding: outerMargin,
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Flexible(child: GameTable()),
                                  Container(
                                    width: 144,
                                    margin: const EdgeInsets.only(left: 32),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        StatusPane(orientation: orientation),
                                        divider,
                                        ControlPane(orientation: orientation),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Orientation.portrait => Padding(
                              padding: outerMargin,
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 32, horizontal: 24),
                                    child: StatusPane(orientation: orientation),
                                  ),
                                  const Flexible(
                                    flex: 0,
                                    child: GameTable(),
                                  ),
                                  ControlPane(orientation: orientation),
                                ],
                              ),
                            ),
                        },
                      ),
                      if (context.watch<Settings>().showDebugPanel())
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
                        },
                      const Align(
                        alignment: Alignment.bottomLeft,
                        child: DebugControlPane(),
                      )
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
