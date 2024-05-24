import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../providers/game_logic.dart';
import '../providers/settings.dart';
import 'solitaire_theme.dart';
import 'tap_hold_detector.dart';

class ControlPane extends ConsumerWidget {
  const ControlPane({super.key, required this.orientation});

  final Orientation orientation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moves = ref.watch(moveHistoryProvider.notifier);
    ref.watch(movesProvider);

    final children = [
      IconButton(
        tooltip: 'Start new game',
        onPressed: () {
          if (context
              .read<SettingsManager>()
              .get(Settings.randomizeThemeColor)) {
            context
                .read<SettingsManager>()
                .set(Settings.themeColor, themeColorPalette.sample(1).single);
          }
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
            // context.read<GameState>().userAction = UserAction.undoMultiple;
          }

          ref.read(moveHistoryProvider.notifier).undo();
        },
        onRelease: () {
          // context.read<GameState>().userAction = null;
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
            // context.read<GameState>().userAction = UserAction.redoMultiple;
          }

          ref.read(moveHistoryProvider.notifier).redo();
        },
        onRelease: () {
          // context.read<GameState>().userAction = null;
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
