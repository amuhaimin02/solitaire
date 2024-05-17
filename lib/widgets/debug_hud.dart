import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../models/game_theme.dart';
import '../providers/settings.dart';

class DebugHUD extends StatelessWidget {
  const DebugHUD({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final settings = context.watch<SettingsManager>();

    final debugText = """
Random seed: ${gameState.gameSeed}
Moves: ${gameState.moves} (History: ${gameState.historyCount})
Reshuffle: ${gameState.reshuffleCount}
Theme mode: ${settings.get(Settings.themeMode).name}
Last move: ${gameState.latestAction}
Undo count: ${gameState.undoCount}
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
            Text(debugText),
          ],
        ),
      ),
    );
  }
}
