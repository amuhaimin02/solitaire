import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
        scrolledUnderElevation: 0,
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
                        width: 400,
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
    final colorScheme = Theme.of(context).colorScheme;

    return FadingEdgeListView(
      verticalPadding: 32,
      children: [
        ListTile(
          title: const Text('Theme mode'),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_6),
                ),
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
        ListTile(
          title: const Text('Select colors'),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Material(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  alignment: WrapAlignment.start,
                  children: [
                    for (final color in themeColorPalette)
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
                        onPressed: () {
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
          ),
        ),
        SwitchListTile(
          title: const Text('AMOLED dark background'),
          selected: settings.get(Settings.themeMode) != ThemeMode.light,
          value: settings.get(Settings.amoledDarkTheme),
          onChanged: settings.get(Settings.themeMode) != ThemeMode.light
              ? (value) {
                  settings.toggle(Settings.amoledDarkTheme);
                }
              : null,
        ),
        SwitchListTile(
          title: const Text('Use standard colors'),
          value: settings.get(Settings.useStandardColors),
          onChanged: (value) {
            settings.toggle(Settings.useStandardColors);
          },
        ),
      ],
    );
  }
}
