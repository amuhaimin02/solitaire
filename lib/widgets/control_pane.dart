import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../animations.dart';
import '../models/game_settings.dart';
import '../models/game_state.dart';
import '../models/game_theme.dart';
import '../utils/system_orientation.dart';

class ControlPane extends StatelessWidget {
  const ControlPane({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final gameTheme = context.watch<GameTheme>();
    final settings = context.watch<GameSettings>();

    final children = [
      IconButton(
        tooltip: 'Toggle theme mode',
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
          size: 24,
        ),
      ),
      IconButton(
        isSelected: gameTheme.usingRandomColors,
        tooltip: 'Toggle dynamic/preset colors',
        onPressed: () {
          gameTheme.toggleUsePresetColors();
        },
        icon: Icon(
          gameTheme.usingRandomColors
              ? MdiIcons.formatPaint
              : MdiIcons.imageFilterBlackWhite,
          size: 24,
        ),
      ),
      IconButton(
        isSelected: gameTheme.usingRandomColors,
        tooltip: 'Change preset colors',
        onPressed: gameTheme.usingRandomColors
            ? () => gameTheme.changePresetColor()
            : null,
        icon: Icon(MdiIcons.dice5, size: 24),
      ),
      IconButton(
        tooltip: 'Toggle device orientation',
        isSelected: settings.screenOrientation() != SystemOrientation.auto,
        onPressed: () {
          context.read<GameSettings>().screenOrientation.toggle();
        },
        icon: Icon(
          switch (settings.screenOrientation()) {
            SystemOrientation.auto => Icons.screen_rotation,
            SystemOrientation.landscape => Icons.stay_current_landscape,
            SystemOrientation.portrait => Icons.stay_current_portrait,
          },
          size: 24,
        ),
      ),
      IconButton(
        isSelected: settings.autoMoveOnDraw(),
        tooltip: 'Auto move on draw',
        onPressed: () {
          context.read<GameSettings>().autoMoveOnDraw.toggle();
        },
        icon: Icon(
          settings.autoMoveOnDraw()
              ? MdiIcons.handBackLeft
              : MdiIcons.handBackLeftOff,
          size: 24,
        ),
      ),
      IconButton(
        isSelected: settings.showMoveHighlight(),
        tooltip: 'Toggle highlights',
        onPressed: () {
          context.read<GameSettings>().showMoveHighlight.toggle();
        },
        icon: Icon(
          settings.showMoveHighlight() ? MdiIcons.eye : MdiIcons.eyeOff,
          size: 24,
        ),
      ),
      IconButton(
        tooltip: 'Toggle debug panel',
        isSelected: gameState.isDebugPanelShowing,
        onPressed: () {
          gameState.toggleDebugPanel();
        },
        icon: Icon(MdiIcons.bug, size: 24),
      ),
      IconButton(
        tooltip: 'Start new game',
        onPressed: () {
          gameState.restoreToDrawPile();
          Future.delayed(
            cardMoveAnimation.duration * 2,
            () {
              HapticFeedback.heavyImpact();
              gameState.startNewGame();
            },
          );
        },
        icon: const Icon(Icons.restart_alt, size: 24),
      ),
      IconButton(
        tooltip: 'Restart game',
        onPressed: () {
          gameState.restartGame();
          HapticFeedback.heavyImpact();
        },
        icon: const Icon(Icons.fast_rewind, size: 24),
      ),
      IconButton(
        tooltip: 'Undo',
        onPressed: gameState.canUndo ? () => gameState.undoMove() : null,
        icon: const Icon(Icons.undo, size: 24),
      ),
      IconButton(
        tooltip: 'Redo',
        onPressed: gameState.canRedo ? () => gameState.redoMove() : null,
        icon: const Icon(Icons.redo, size: 24),
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
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center,
            children: children,
          ),
        );
      },
    );
  }
}
