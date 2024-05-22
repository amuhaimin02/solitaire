import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../providers/settings.dart';
import 'solitaire_theme.dart';
import 'tap_hold_detector.dart';

class ControlPane extends StatelessWidget {
  const ControlPane({super.key, required this.orientation});

  final Orientation orientation;

  @override
  Widget build(BuildContext context) {
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
          context.read<GameState>().startNewGame();
        },
        icon: const Icon(Icons.restart_alt, size: 24),
      ),
      IconButton(
        tooltip: 'Hint',
        onPressed: () {
          context.read<GameState>().highlightPossibleMoves();
        },
        icon: const Icon(Icons.lightbulb, size: 24),
      ),
      TapHoldDetector(
        interval: const Duration(milliseconds: 100),
        delayBeforeHold: const Duration(milliseconds: 500),
        onTap: () {
          context.read<GameState>().undoMove();
        },
        onHold: (duration) {
          if (duration == Duration.zero) {
            HapticFeedback.heavyImpact();
            context.read<GameState>().userAction = UserAction.undoMultiple;
          }

          context.read<GameState>().undoMove();
        },
        onRelease: () {
          context.read<GameState>().userAction = null;
        },
        child: IconButton(
          tooltip: 'Undo',
          onPressed: context.watch<GameState>().canUndo ? () {} : null,
          icon: const Icon(Icons.undo, size: 24),
        ),
      ),
      TapHoldDetector(
        interval: const Duration(milliseconds: 100),
        delayBeforeHold: const Duration(milliseconds: 500),
        onTap: () {
          context.read<GameState>().redoMove();
        },
        onHold: (duration) {
          if (duration == Duration.zero) {
            HapticFeedback.heavyImpact();
            context.read<GameState>().userAction = UserAction.redoMultiple;
          }

          context.read<GameState>().redoMove();
        },
        onRelease: () {
          context.read<GameState>().userAction = null;
        },
        child: IconButton(
          tooltip: 'Redo',
          onPressed: context.watch<GameState>().canRedo ? () {} : null,
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
