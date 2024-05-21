import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../providers/settings.dart';

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
