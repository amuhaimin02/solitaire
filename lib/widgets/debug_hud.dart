import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';

class DebugHUD extends StatelessWidget {
  const DebugHUD({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    return DefaultTextStyle(
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: Colors.white,
          ),
      child: Container(
        color: Colors.black.withOpacity(0.4),
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
          ],
        ),
      ),
    );
  }
}
