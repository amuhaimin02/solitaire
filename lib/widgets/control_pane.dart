import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../animations.dart';
import '../models/game_state.dart';
import '../models/game_theme.dart';

class ControlPane extends StatelessWidget {
  const ControlPane({super.key, required this.orientation});

  final Orientation orientation;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.watch<GameTheme>();

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
        onPressed: () {},
        icon: const Icon(Icons.lightbulb, size: 24),
      ),
      IconButton(
        tooltip: 'Undo',
        onPressed: context.watch<GameState>().canUndo
            ? () => context.read<GameState>().undoMove()
            : null,
        icon: const Icon(Icons.undo, size: 24),
      ),
      IconButton(
        tooltip: 'Redo',
        onPressed: context.watch<GameState>().canRedo
            ? () => context.read<GameState>().redoMove()
            : null,
        icon: const Icon(Icons.redo, size: 24),
      ),
    ];
    switch (orientation) {
      case Orientation.portrait:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: children,
        );
      case Orientation.landscape:
        return Wrap(
          direction: Axis.vertical,
          spacing: 8,
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          children: children,
        );
    }
  }
}
