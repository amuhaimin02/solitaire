import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/game_logic.dart';
import '../../../providers/statistics.dart';
import '../../../providers/themes.dart';

class RestartDialog extends ConsumerWidget {
  const RestartDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Restart game?'),
      content: const Text(
          'Do you want to restart this game from beginning or redeal for a new game?'),
      actionsOverflowButtonSpacing: 8,
      actions: [
        FilledButton.tonalIcon(
          onPressed: () {
            Navigator.pop(context);
            ref.read(gameControllerProvider.notifier).restart();
          },
          icon: const Icon(Icons.fast_rewind),
          label: const Text('Restart'),
        ),
        FilledButton.icon(
          onPressed: () {
            if (!ref.read(isGameFinishedProvider)) {
              // Record current game to statistics
              ref.read(statisticsUpdaterProvider.notifier).recordCurrentGame();
            }

            Navigator.pop(context);
            final game = ref.read(currentGameProvider);
            ref.read(gameControllerProvider.notifier).startNew(game.kind);

            // Change theme color when starting new game
            ref
                .read(themeBaseRandomizeColorProvider.notifier)
                .tryShuffleColor();
          },
          icon: const Icon(Icons.restart_alt),
          label: const Text('New game'),
        ),
      ],
    );
  }
}
