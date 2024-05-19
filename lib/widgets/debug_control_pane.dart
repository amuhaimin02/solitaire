import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../models/game_theme.dart';
import '../models/pile.dart';
import '../providers/settings.dart';
import '../utils/system_orientation.dart';

class DebugControlPane extends StatefulWidget {
  const DebugControlPane({super.key});

  @override
  State<DebugControlPane> createState() => _DebugControlPaneState();
}

class _DebugControlPaneState extends State<DebugControlPane> {
  bool _showButtons = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsManager>();

    final children = [
      const BackButton(),
      IconButton(
        tooltip: 'Toggle theme mode',
        onPressed: () {
          final currentThemeMode = settings.get(Settings.themeMode);
          if (currentThemeMode == ThemeMode.system) {
            settings.set(
                Settings.themeMode,
                Theme.of(context).brightness == Brightness.light
                    ? ThemeMode.dark
                    : ThemeMode.light);
          } else {
            settings.set(
                Settings.themeMode,
                currentThemeMode == ThemeMode.light
                    ? ThemeMode.dark
                    : ThemeMode.light);
          }
        },
        icon: Icon(
          switch (settings.get(Settings.themeMode)) {
            ThemeMode.light => Icons.light_mode,
            ThemeMode.dark => Icons.dark_mode,
            ThemeMode.system => Icons.contrast,
          },
          size: 24,
        ),
      ),
      IconButton(
        tooltip: 'Toggle dynamic/preset colors',
        onPressed: () {
          settings.toggle(Settings.useDynamicColors);
        },
        icon: Icon(
          settings.get(Settings.useDynamicColors)
              ? MdiIcons.formatPaint
              : MdiIcons.imageFilterBlackWhite,
          size: 24,
        ),
      ),
      IconButton(
        tooltip: 'Change preset colors',
        onPressed: !settings.get(Settings.useDynamicColors)
            ? () => settings.set(
                Settings.presetColor, GameTheme.colorPalette.sample(1).single)
            : null,
        icon: Icon(MdiIcons.dice5),
      ),
      IconButton(
        tooltip: 'Use standard colors',
        isSelected: settings.get(Settings.useStandardColors),
        onPressed: () => settings.toggle(Settings.useStandardColors),
        icon: Icon(MdiIcons.invertColors),
      ),
      IconButton(
        tooltip: 'Use gradient background',
        isSelected: settings.get(Settings.useGradientBackground),
        onPressed: () => settings.toggle(Settings.useGradientBackground),
        icon: Icon(MdiIcons.gradientHorizontal),
      ),
      IconButton(
        tooltip: 'Toggle device orientation',
        onPressed: () {
          context.read<SettingsManager>().toggle(Settings.screenOrientation);
        },
        icon: Icon(
          switch (settings.get(Settings.screenOrientation)) {
            SystemOrientation.auto => Icons.screen_rotation_alt,
            SystemOrientation.landscape => Icons.stay_current_landscape,
            SystemOrientation.portrait => Icons.stay_current_portrait,
          },
          size: 24,
        ),
      ),
      IconButton(
        isSelected: settings.get(Settings.autoMoveLevel) != AutoMoveLevel.off,
        tooltip: 'Auto move on draw',
        onPressed: () {
          context.read<SettingsManager>().toggle(Settings.autoMoveLevel);
        },
        icon: Icon(
          switch (settings.get(Settings.autoMoveLevel)) {
            AutoMoveLevel.off => MdiIcons.handBackLeftOff,
            AutoMoveLevel.onDraw => MdiIcons.handBackLeft,
            AutoMoveLevel.full => MdiIcons.monitor,
          },
          size: 24,
        ),
      ),
      IconButton(
        isSelected: settings.get(Settings.showMoveHighlight),
        tooltip: 'Toggle highlights',
        onPressed: () {
          context.read<SettingsManager>().toggle(Settings.showMoveHighlight);
        },
        icon: Icon(
          settings.get(Settings.showMoveHighlight)
              ? MdiIcons.eye
              : MdiIcons.eyeOff,
          size: 24,
        ),
      ),
      IconButton(
        tooltip: 'Toggle debug panel',
        isSelected: settings.get(Settings.showDebugPanel),
        onPressed: () {
          settings.toggle(Settings.showDebugPanel);
        },
        icon: Icon(MdiIcons.bug),
      ),
      IconButton(
        tooltip: 'Test custom layout',
        onPressed: () {
          context.read<GameState>().testCustomLayout();
        },
        icon: Icon(MdiIcons.cardsPlaying),
      ),
    ];

    return Container(
      color: colorScheme.surface.withOpacity(0.2),
      child: Wrap(
        children: [
          IconButton(
            tooltip: 'Expand/contract debug buttons',
            onPressed: () {
              setState(() {
                _showButtons = !_showButtons;
              });
            },
            icon: _showButtons
                ? const Icon(Icons.keyboard_double_arrow_left)
                : const Icon(Icons.keyboard_double_arrow_right),
          ),
          if (_showButtons) ...children,
        ],
      ),
    );
  }
}
