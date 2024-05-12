import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../models/game_theme.dart';

class DebugHUD extends StatelessWidget {
  const DebugHUD({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final gameTheme = context.watch<GameTheme>();

    final debugText = """
Random seed: ${gameState.gameSeed}
Moves: ${gameState.moves} (History: ${gameState.historyCount})
Reshuffle: ${gameState.reshuffleCount}
Theme mode: ${gameTheme.currentMode.name}
Theme color palette: ${gameTheme.currentPresetColor?.shade500 ?? '(dynamic)'}
Last move: ${gameState.latestAction}
.
.
.
.
.
.
.
.
.
.
.
.
""";

    return DefaultTextStyle(
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: Colors.white.withOpacity(1),
          ),
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            StreamBuilder<Null>(
              stream: Stream.periodic(const Duration(milliseconds: 50)),
              builder: (context, snapshot) {
                final playtimeString = gameState.playTime.toString();
                return Text(
                  'Time: ${playtimeString.substring(0, playtimeString.lastIndexOf('.') + 2)}',
                );
              },
            ),
            Text(debugText),
          ],
        ),
      ),
    );
  }
}
