import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pile.dart';
import '../models/rules/simple.dart';
import '../providers/settings.dart';
import '../widgets/fading_edge_list_view.dart';
import '../widgets/game_table.dart';
import '../widgets/section_title.dart';
import '../widgets/solitaire_theme.dart';

class CustomizeScreen extends StatelessWidget {
  const CustomizeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = SolitaireTheme.of(context);

    final rules = SimpleSolitaire();
    final cards = PlayCards.fromRules(rules);
    cards(const Draw()).addAll(rules.prepareDrawPile(Random(1)).allFaceDown);

    rules.setup(cards);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize'),
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
                        decoration: BoxDecoration(
                          color: theme.tableBackgroundColor,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: SizedBox(
                            width: 400,
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
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.tableBackgroundColor,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          margin: const EdgeInsets.all(24),
                          padding: const EdgeInsets.all(24),
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
                      Expanded(
                        flex: 3,
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

    final randomizeColor = settings.get(Settings.randomizeThemeColor);
    final coloredBackground = settings.get(Settings.coloredBackground);
    final amoledDarkTheme = settings.get(Settings.amoledDarkTheme);

    return FadingEdgeListView(
      verticalPadding: 32,
      children: [
        const SectionTitle('Base theme', first: true),
        ListTile(
          title: const Text('Theme mode'),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SegmentedButton<ThemeMode>(
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
              color: colorScheme.surfaceTint.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    CheckboxListTile(
                      title: const Text('Randomize color'),
                      secondary: const Icon(Icons.shuffle),
                      subtitle: const Text(
                          'Colors will change when starting a new game'),
                      value: randomizeColor,
                      onChanged: (value) {
                        if (value == true) {
                          settings.set(Settings.randomizeThemeColor, true);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Wrap(
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
                              if (randomizeColor) {
                                settings.set(
                                    Settings.randomizeThemeColor, false);
                              }
                              settings.set(Settings.themeColor, color);
                            },
                            isSelected: !randomizeColor &&
                                settings.get(Settings.themeColor).value ==
                                    color.value,
                            iconSize: 32,
                            icon: const Icon(Icons.circle_outlined),
                            selectedIcon: const Icon(Icons.circle),
                            color: color,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SectionTitle('Background'),
        SwitchListTile(
          title: const Text('AMOLED dark background'),
          subtitle: const Text('Usew pitch black background when on dark mode'),
          value: amoledDarkTheme,
          onChanged: !coloredBackground &&
                  settings.get(Settings.themeMode) != ThemeMode.light
              ? (value) {
                  settings.toggle(Settings.amoledDarkTheme);
                }
              : null,
        ),
        SwitchListTile(
          title: const Text('Colored background'),
          subtitle:
              const Text('Use strong colors of the theme for the background'),
          value: coloredBackground,
          onChanged: (value) {
            settings.toggle(Settings.coloredBackground);
          },
        ),
        const SectionTitle('Cards'),
        SwitchListTile(
          title: const Text('Standard card colors'),
          subtitle: const Text('Use standard red-black card face colors'),
          value: settings.get(Settings.useStandardCardColors),
          onChanged: (value) {
            settings.toggle(Settings.useStandardCardColors);
          },
        ),
      ],
    );
  }
}
