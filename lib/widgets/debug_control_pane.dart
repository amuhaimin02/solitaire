import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../animations.dart';
import '../models/game_state.dart';
import '../models/game_theme.dart';
import '../providers/settings.dart';
import '../utils/system_orientation.dart';

class DebugControlPane extends StatelessWidget {
  const DebugControlPane({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<Settings>();
    final gameTheme = context.watch<GameTheme>();

    final children = [
      IconButton(
        tooltip: 'Toggle theme mode',
        onPressed: !settings.useStandardColors()
            ? () {
                final currentThemeMode = gameTheme.currentMode;
                if (currentThemeMode == ThemeMode.system) {
                  gameTheme.changeMode(
                      Theme.of(context).brightness == Brightness.light
                          ? ThemeMode.dark
                          : ThemeMode.light);
                } else {
                  gameTheme.changeMode(gameTheme.currentMode == ThemeMode.light
                      ? ThemeMode.dark
                      : ThemeMode.light);
                }
              }
            : null,
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
        tooltip: 'Toggle dynamic/preset colors',
        onPressed: !settings.useStandardColors()
            ? () {
                gameTheme.toggleUsePresetColors();
              }
            : null,
        icon: Icon(
          gameTheme.usingRandomColors
              ? MdiIcons.formatPaint
              : MdiIcons.imageFilterBlackWhite,
          size: 24,
        ),
      ),
      IconButton(
        tooltip: 'Change preset colors',
        onPressed: !settings.useStandardColors() && gameTheme.usingRandomColors
            ? () => gameTheme.changePresetColor()
            : null,
        icon: Icon(MdiIcons.dice5, size: 24),
      ),
      IconButton(
        tooltip: 'Use standard colors',
        isSelected: settings.useStandardColors(),
        onPressed: () => settings.useStandardColors.toggle(),
        icon: Icon(MdiIcons.invertColors, size: 24),
      ),
      IconButton(
        tooltip: 'Toggle device orientation',
        onPressed: () {
          context.read<Settings>().screenOrientation.toggle();
        },
        icon: Icon(
          switch (settings.screenOrientation()) {
            SystemOrientation.auto => Icons.screen_rotation_alt,
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
          context.read<Settings>().autoMoveOnDraw.toggle();
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
          context.read<Settings>().showMoveHighlight.toggle();
        },
        icon: Icon(
          settings.showMoveHighlight() ? MdiIcons.eye : MdiIcons.eyeOff,
          size: 24,
        ),
      ),
      IconButton(
        tooltip: 'Toggle debug panel',
        isSelected: settings.showDebugPanel(),
        onPressed: () {
          settings.showDebugPanel.toggle();
        },
        icon: Icon(MdiIcons.bug, size: 24),
      ),
      IconButton(
        tooltip: 'Test custom layout',
        onPressed: () {
          context.read<GameState>().testCustomLayout();
        },
        icon: Icon(MdiIcons.cardsPlaying, size: 24),
      ),
    ];

    return Container(
      color: colorScheme.surface.withOpacity(0.2),
      width: double.infinity,
      child: Wrap(
        children: children,
      ),
    );
  }
}
