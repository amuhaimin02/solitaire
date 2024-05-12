import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../models/game_state.dart';
import '../models/game_theme.dart';

class GameHUD extends StatelessWidget {
  const GameHUD({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final gameTheme = context.watch<GameTheme>();

    final children = [
      IconButton(
        tooltip: 'Change theme',
        onPressed: () {
          final gameTheme = context.read<GameTheme>();
          final currentThemeMode = gameTheme.currentMode;
          final nextThemeMode = ThemeMode.values[
              (ThemeMode.values.indexOf(currentThemeMode) + 1) %
                  ThemeMode.values.length];

          gameTheme.changeMode(nextThemeMode);
        },
        icon: Icon(
          switch (gameTheme.currentMode) {
            ThemeMode.light => Icons.light_mode,
            ThemeMode.dark => Icons.dark_mode,
            ThemeMode.system => Icons.contrast,
          },
          size: 32,
        ),
      ),
      IconButton(
        isSelected: gameTheme.usingRandomColors,
        tooltip: 'Toggle random theme',
        onPressed: () {
          gameTheme.toggleUsePresetColors(!gameTheme.usingRandomColors);
        },
        icon: Icon(
          gameTheme.usingRandomColors
              ? MdiIcons.dice5
              : MdiIcons.imageFilterBlackWhite,
          size: 32,
        ),
      ),
      IconButton(
        tooltip: 'Start new game',
        onPressed: () {
          gameTheme.changePresetColor();
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
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            direction: switch (orientation) {
              Orientation.landscape => Axis.vertical,
              Orientation.portrait => Axis.horizontal,
            },
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center,
            children: children,
          ),
        );
      },
    );
  }
}
