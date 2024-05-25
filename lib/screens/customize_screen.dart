import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../animations.dart';
import '../models/game/simple.dart';
import '../models/pile.dart';
import '../models/play_table.dart';
import '../providers/settings.dart';
import '../widgets/fading_edge_list_view.dart';
import '../widgets/game_table.dart';
import '../widgets/section_title.dart';
import '../widgets/solitaire_theme.dart';

class CustomizeScreen extends ConsumerWidget {
  const CustomizeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewPadding = MediaQuery.of(context).viewPadding;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize'),
        scrolledUnderElevation: 0,
      ),
      body: Padding(
        padding:
            EdgeInsets.only(left: viewPadding.left, right: viewPadding.right),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final orientation = constraints.maxWidth > 800
                ? Orientation.landscape
                : Orientation.portrait;

            return switch (orientation) {
              Orientation.landscape => Row(
                  children: [
                    Expanded(
                      child: _buildTablePreview(context),
                    ),
                    const SizedBox(
                      width: 480,
                      child: _SettingsList(),
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
                          child: _buildTablePreview(context),
                        ),
                        const Expanded(
                          flex: 3,
                          child: _SettingsList(),
                        ),
                      ],
                    ),
                  ),
                ),
            };
          },
        ),
      ),
    );
  }

  Widget _buildTablePreview(BuildContext context) {
    final theme = SolitaireTheme.of(context);

    // TODO: Create function to generate demo setup
    final rules = SimpleSolitaire();
    PlayTable table = PlayTable.fromGame(rules)
        .modify(const Draw(), rules.prepareDrawPile(Random(1)));
    table = rules.setup(table);

    return AnimatedContainer(
      duration: themeChangeAnimation.duration,
      curve: themeChangeAnimation.curve,
      decoration: BoxDecoration(
        color: theme.tableBackgroundColor,
        borderRadius: BorderRadius.circular(32),
      ),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
          child: GameTable(
            rules: rules,
            table: table,
            interactive: false,
            animateMovement: false,
          ),
        ),
      ),
    );
  }
}

class _SettingsList extends ConsumerWidget {
  const _SettingsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    final themeMode = ref.watch(appThemeModeProvider);
    final themeColor = ref.watch(appThemeColorProvider);

    final randomizeColor = ref.watch(randomizeThemeColorProvider);
    final coloredBackground = ref.watch(coloredBackgroundProvider);
    final amoledDarkTheme = ref.watch(amoledBackgroundProvider);

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
              selected: {themeMode},
              onSelectionChanged: (value) {
                ref.read(appThemeModeProvider.notifier).set(value.single);
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
                      title: const Text('Random color'),
                      secondary: const Icon(Icons.shuffle),
                      subtitle: const Text(
                          'Color changes every time new game starts'),
                      value: randomizeColor,
                      onChanged: (value) {
                        if (value == true) {
                          ref
                              .read(randomizeThemeColorProvider.notifier)
                              .set(true);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.start,
                      children: [
                        for (final color in themeColorPalette)
                          IconButton(
                            onPressed: () {
                              if (randomizeColor) {
                                ref
                                    .read(randomizeThemeColorProvider.notifier)
                                    .set(false);
                              }
                              ref
                                  .read(appThemeColorProvider.notifier)
                                  .set(color);
                            },
                            isSelected: !randomizeColor &&
                                themeColor.value == color.value,
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
          subtitle: const Text('Use pitch black background when on dark mode'),
          value: amoledDarkTheme,
          onChanged: !coloredBackground && themeMode != ThemeMode.light
              ? (value) {
                  ref.read(amoledBackgroundProvider.notifier).toggle();
                }
              : null,
        ),
        SwitchListTile(
          title: const Text('Colored table background'),
          subtitle: const Text(
              'Use strong colors of the theme for the table background'),
          value: coloredBackground,
          onChanged: (value) {
            ref.read(coloredBackgroundProvider.notifier).toggle();
          },
        ),
        const SectionTitle('Cards'),
        SwitchListTile(
          title: const Text('Standard card colors'),
          subtitle: const Text('Use standard red-black card face colors'),
          value: ref.watch(standardCardColorProvider),
          onChanged: (value) {
            ref.read(standardCardColorProvider.notifier).toggle();
          },
        ),
      ],
    );
  }
}
