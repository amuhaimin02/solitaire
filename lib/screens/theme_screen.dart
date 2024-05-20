import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_theme.dart';
import '../models/pile.dart';
import '../models/rules/simple.dart';
import '../providers/settings.dart';
import '../widgets/fading_edge_list_view.dart';
import '../widgets/game_table.dart';
import '../widgets/solitaire_theme.dart';

class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rules = SimpleSolitaire();
    final cards = PlayCards.fromRules(rules);
    cards(const Draw()).addAll(rules.prepareDrawPile(Random(1)).allFaceDown);

    rules.setup(cards);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Themes'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final orientation = constraints.maxWidth > 800
              ? Orientation.landscape
              : Orientation.portrait;

          return switch (orientation) {
            Orientation.landscape => Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 240,
                        margin: const EdgeInsets.all(24),
                        child: Center(
                          child: GameTable(
                            rules: rules,
                            cards: cards,
                            interactive: false,
                            animateMovement: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 480,
                    child: _buildSettingsList(context),
                  ),
                ],
              ),
            Orientation.portrait => Center(
                child: SizedBox(
                  width: 600,
                  child: Column(
                    children: [
                      Container(
                        width: 200,
                        margin: const EdgeInsets.all(24),
                        child: Center(
                          child: GameTable(
                            rules: rules,
                            cards: cards,
                            interactive: false,
                            animateMovement: false,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _buildSettingsList(context),
                      ),
                    ],
                  ),
                ),
              ),
          };
        },
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    final settings = context.watch<SettingsManager>();
    return SolitaireAdjustedTheme(
      child: FadingEdgeListView(
        children: [
          ListTile(
            title: const Text('Theme mode'),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('System'),
                      icon: Icon(Icons.brightness_6)),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode),
                  ),
                ],
                selected: {settings.get(Settings.themeMode)},
                onSelectionChanged: (value) {
                  settings.set(Settings.themeMode, value.single);
                },
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Dynamic colors'),
            subtitle: const Text(
                'Use your device accent colors as the baseline of the theme'),
            value: settings.get(Settings.useDynamicColors),
            onChanged: (value) {
              settings.toggle(Settings.useDynamicColors);
            },
          ),
          SwitchListTile(
            title: const Text('Contrast background'),
            subtitle:
                const Text('Use strong contrast version of the background'),
            value: settings.get(Settings.strongContrastBackground),
            onChanged: (value) {
              settings.toggle(Settings.strongContrastBackground);
            },
          ),
          SwitchListTile(
            title: const Text('Gradient background'),
            subtitle: const Text('Use gradient version of the background'),
            value: settings.get(Settings.useGradientBackground),
            onChanged: (value) {
              settings.toggle(Settings.useGradientBackground);
            },
          ),
          ListTile(
            enabled: !settings.get(Settings.useDynamicColors),
            title: const Text('Select colors'),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                alignment: WrapAlignment.start,
                children: [
                  for (final color in GameTheme.colorPalette)
                    // ColorButton(
                    //   size: 40,
                    //   color: color,
                    //   isSelected: settings.get(Settings.presetColor).value ==
                    //       color.value,
                    //   onTap: () {
                    //     settings.set(Settings.presetColor, color);
                    //   },
                    // ),
                    IconButton(
                      onPressed: settings.get(Settings.useDynamicColors)
                          ? null
                          : () {
                              settings.set(Settings.presetColor, color);
                            },
                      isSelected: settings.get(Settings.presetColor).value ==
                          color.value,
                      iconSize: 32,
                      icon: const Icon(Icons.circle_outlined),
                      selectedIcon: const Icon(Icons.circle),
                      color: color,
                    ),
                ],
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Use standard colors'),
            value: settings.get(Settings.useStandardColors),
            onChanged: (value) {
              settings.toggle(Settings.useStandardColors);
            },
          ),
        ],
      ),
    );
  }
}
