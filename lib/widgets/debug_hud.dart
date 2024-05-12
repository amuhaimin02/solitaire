import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../models/game_state.dart';
import '../models/game_theme.dart';

class DebugHUD extends StatelessWidget {
  const DebugHUD({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final gameTheme = context.watch<GameTheme>();

    return IgnorePointer(
      ignoring: true,
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
        child: Container(
          color: Colors.black.withOpacity(0.2),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Random seed: ${gameState.gameSeed}'),
              Text('Moves: ${gameState.moves}'),
              StreamBuilder<Null>(
                stream: Stream.periodic(const Duration(milliseconds: 50)),
                builder: (context, snapshot) {
                  final playtimeString = gameState.playTime.toString();
                  return Text(
                    'Time: ${playtimeString.substring(0, playtimeString.lastIndexOf('.') + 2)}',
                  );
                },
              ),
              Text('History: ${gameState.historyCount}'),
              Text('Reshuffle: ${gameState.reshuffleCount}'),
              Text('Theme mode: ${gameTheme.currentMode.name}'),
              Text(
                  'Theme color palette: ${gameTheme.currentPresetColor?.shade500 ?? '(dynamic)'}'),
            ],
          ),
        ),
      ),
    );
  }
}
