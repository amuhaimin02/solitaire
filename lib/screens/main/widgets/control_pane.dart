import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/user_action.dart';
import '../../../providers/game_logic.dart';
import '../../../providers/game_move_history.dart';
import '../../../providers/settings.dart';
import '../../../widgets/message_overlay.dart';
import '../../../widgets/mini_toast.dart';
import '../../../widgets/tap_hold_detector.dart';
import 'restart_dialog.dart';

class ControlPane extends ConsumerWidget {
  const ControlPane({super.key, required this.orientation});

  final Orientation orientation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moves = ref.watch(moveHistoryProvider.notifier);
    final game = ref.watch(currentGameProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Only watching so this widget can be updated whenever move count changes.
    // Mainly for undo/redo button
    ref.watch(currentMoveProvider);

    final children = [
      IconButton(
        tooltip: 'Restart / new game',
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const RestartDialog(),
          );
        },
        icon: const Icon(Icons.restart_alt, size: 24),
      ),
      if (game.kind.canShowHints && ref.watch(settingsShowHintButtonProvider))
        IconButton(
          tooltip: 'Hint',
          onPressed: () {
            final hasMoves =
                ref.read(gameControllerProvider.notifier).highlightHints();
            if (!hasMoves) {
              final overlay = MiniToast(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
                child: const Text('No moves available'),
              );

              MessageOverlay.of(context).show(overlay);
            }
          },
          icon: const Icon(Icons.lightbulb, size: 24),
        ),
      if (game.kind.canUndoAndRedo &&
          ref.watch(settingsShowUndoRedoButtonProvider)) ...[
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
