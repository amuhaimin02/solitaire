import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/user_action.dart';
import '../../../providers/game_logic.dart';
import '../../../providers/game_move_history.dart';
import '../../../providers/settings.dart';
import '../../../providers/themes.dart';
import '../../../widgets/tap_hold_detector.dart';

class ControlPane extends ConsumerWidget {
  const ControlPane({super.key, required this.orientation});

  final Orientation orientation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moves = ref.watch(moveHistoryProvider.notifier);

    // Only watching so this widget can be updated whenever move count changes.
    // Mainly for undo/redo button
    ref.watch(currentMoveProvider);

    final children = [
      IconButton(
        tooltip: 'Restart / new game',
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const _RestartDialog(),
          );
        },
        icon: const Icon(Icons.restart_alt, size: 24),
      ),
      if (ref.watch(settingsShowHintButtonProvider))
        IconButton(
          tooltip: 'Hint',
          onPressed: () {
            final hasMoves =
                ref.read(gameControllerProvider.notifier).highlightHints();
            if (!hasMoves) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No moves available')),
              );
            }
          },
          icon: const Icon(Icons.lightbulb, size: 24),
        ),
      if (ref.watch(settingsShowUndoRedoButtonProvider)) ...[
        TapHoldDetector(
          interval: const Duration(milliseconds: 100),
          delayBeforeHold: const Duration(milliseconds: 500),
          onTap: () {
            ref.read(moveHistoryProvider.notifier).undo();
          },
          onHold: (duration) {
            if (duration == Duration.zero) {
              HapticFeedback.heavyImpact();
              ref
                  .read(userActionProvider.notifier)
                  .set(UserActionOptions.undoMultiple);
            }

            ref.read(moveHistoryProvider.notifier).undo();
          },
          onRelease: () {
            ref.read(userActionProvider.notifier).clear();
          },
          child: IconButton(
            tooltip: 'Undo',
            onPressed: moves.canUndo() ? () {} : null,
            icon: const Icon(Icons.undo, size: 24),
          ),
        ),
        TapHoldDetector(
          interval: const Duration(milliseconds: 100),
          delayBeforeHold: const Duration(milliseconds: 500),
          onTap: () {
            ref.read(moveHistoryProvider.notifier).redo();
          },
          onHold: (duration) {
            if (duration == Duration.zero) {
              HapticFeedback.heavyImpact();
              ref
                  .read(userActionProvider.notifier)
                  .set(UserActionOptions.redoMultiple);
            }

            ref.read(moveHistoryProvider.notifier).redo();
          },
          onRelease: () {
            ref.read(userActionProvider.notifier).clear();
          },
          child: IconButton(
            tooltip: 'Redo',
            onPressed: moves.canRedo() ? () {} : null,
            icon: const Icon(Icons.redo, size: 24),
          ),
        ),
      ],
    ];

    return switch (orientation) {
      Orientation.portrait => Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: children,
          ),
        ),
      Orientation.landscape => Wrap(
          direction: Axis.vertical,
          spacing: 4,
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          children: children,
        ),
    };
  }
}

class _RestartDialog extends ConsumerWidget {
  const _RestartDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Restart game?'),
      content: const Text(
          'Do you want to restart this game from beginning or redeal for a new game?'),
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
            Navigator.pop(context);
            ref
                .read(themeBaseRandomizeColorProvider.notifier)
                .tryShuffleColor();
            final game = ref.read(currentGameProvider);
            ref.read(gameControllerProvider.notifier).startNew(game.kind);
          },
          icon: const Icon(Icons.restart_alt),
          label: const Text('New game'),
        ),
      ],
    );
  }
}
