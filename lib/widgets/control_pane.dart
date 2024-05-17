import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../animations.dart';
import '../models/game_state.dart';
import '../models/game_theme.dart';
import 'tap_hold_detector.dart';

class ControlPane extends StatelessWidget {
  const ControlPane({super.key, required this.orientation});

  final Orientation orientation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final children = [
      IconButton(
        tooltip: 'Start new game',
        onPressed: () {
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

    return IconButtonTheme(
      data: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onPrimaryContainer,
        ),
      ),
      child: switch (orientation) {
        Orientation.portrait => Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: children,
          ),
        Orientation.landscape => Wrap(
            direction: Axis.vertical,
            spacing: 8,
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            children: children,
          ),
      },
    );
  }
}
