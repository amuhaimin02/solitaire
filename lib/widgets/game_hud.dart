import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../models/game_state.dart';

class GameHUD extends StatelessWidget {
  const GameHUD({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    final children = [
      IconButton(
        tooltip: 'Change theme',
        onPressed: () {
          final themeChanger = context.read<ThemeChanger>();
          final currentThemeMode = themeChanger.current;
          final nextThemeMode = ThemeMode.values[
              (ThemeMode.values.indexOf(currentThemeMode) + 1) %
                  ThemeMode.values.length];

          themeChanger.change(nextThemeMode);
        },
        icon: Icon(
          switch (context.watch<ThemeChanger>().current) {
            ThemeMode.light => Icons.light_mode,
            ThemeMode.dark => Icons.dark_mode,
            ThemeMode.system => Icons.contrast,
          },
          size: 32,
        ),
      ),
      IconButton(
        tooltip: 'Start new game',
        onPressed: () {
          gameState.startNewGame();
        },
        icon: const Icon(Icons.restart_alt, size: 32),
      ),
      IconButton(
        tooltip: 'Restart game',
        onPressed: () {
          gameState.restartGame();
        },
        icon: const Icon(Icons.fast_rewind, size: 32),
      ),
      IconButton(
        tooltip: 'Undo',
        onPressed: () {
          gameState.undoMove();
        },
        icon: const Icon(Icons.undo, size: 32),
      ),
      IconButton(
        tooltip: 'Redo',
        onPressed: () {
          gameState.redoMove();
        },
        icon: const Icon(Icons.redo, size: 32),
      ),
    ];

    return OrientationBuilder(
      builder: (context, orientation) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: switch (orientation) {
            Orientation.landscape => Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: children,
              ),
            Orientation.portrait => Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: children,
              ),
          },
        );
      },
    );
  }
}
