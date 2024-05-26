import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_action.dart';
import '../providers/game_logic.dart';
import '../providers/themes.dart';
import 'tap_hold_detector.dart';

class ControlPane extends ConsumerWidget {
  const ControlPane({super.key, required this.orientation});

  final Orientation orientation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moves = ref.watch(moveHistoryProvider.notifier);

    // Only watching so this widget can be updated whenever move count changes.
    // Mainly for undo/redo button
    ref.watch(moveCountProvider);

    final children = [
      IconButton(
        tooltip: 'Start new game',
        onPressed: () {
          ref.read(themeBaseRandomizeColorProvider.notifier).tryShuffleColor();
          final game = ref.read(currentGameProvider);
          ref.read(gameControllerProvider.notifier).startNew(game.rules);
        },
        icon: const Icon(Icons.restart_alt, size: 24),
      ),
      IconButton(
        tooltip: 'Hint',
        onPressed: () {
          ref.read(gameControllerProvider.notifier).highlightHints();
        },
        icon: const Icon(Icons.lightbulb, size: 24),
      ),
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
          onPressed: moves.canUndo ? () {} : null,
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
          onPressed: moves.canRedo ? () {} : null,
          icon: const Icon(Icons.redo, size: 24),
        ),
      ),
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
