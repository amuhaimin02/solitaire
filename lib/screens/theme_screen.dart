import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../animations.dart';
import '../models/card.dart';
import '../models/direction.dart';
import '../models/pile.dart';
import '../models/play_table.dart';
import '../models/table_layout.dart';
import '../providers/themes.dart';
import '../widgets/game_table.dart';
import '../widgets/section_title.dart';
import '../widgets/solitaire_theme.dart';
import '../widgets/two_pane.dart';

final _sampleLayout = TableLayout(
  gridSize: const Size(4, 3),
  items: [
    TableLayoutItem(
      kind: const Draw(),
      region: const Rect.fromLTWH(3, 0, 1, 1),
    ),
    TableLayoutItem(
      kind: const Discard(),
      region: const Rect.fromLTWH(2, 0, 2, 1),
    ),
    for (int i = 0; i < 2; i++)
      TableLayoutItem(
        kind: Foundation(i),
        region: Rect.fromLTWH(i.toDouble(), 0, 1, 1),
      ),
    for (int i = 0; i < 4; i++)
      TableLayoutItem(
        kind: Tableau(i),
        region: Rect.fromLTWH(i.toDouble(), 1, 1, 2),
        stackDirection: Direction.down,
      ),
  ],
);

final _samplePlayTable = PlayTable.fromMap({
  const Draw(): const [
    PlayCard(Suit.heart, Rank.eight, flipped: true),
    PlayCard(Suit.club, Rank.two, flipped: true),
  ],
  const Tableau(0): const [
    PlayCard(Suit.spade, Rank.ace),
  ],
  const Tableau(1): const [
    PlayCard(Suit.diamond, Rank.four, flipped: true),
    PlayCard(Suit.heart, Rank.five),
  ],
  const Tableau(2): const [
    PlayCard(Suit.diamond, Rank.seven, flipped: true),
    PlayCard(Suit.club, Rank.six, flipped: true),
    PlayCard(Suit.club, Rank.queen),
  ],
  const Tableau(3): const [
    PlayCard(Suit.heart, Rank.three, flipped: true),
    PlayCard(Suit.diamond, Rank.ten, flipped: true),
    PlayCard(Suit.spade, Rank.eight, flipped: true),
    PlayCard(Suit.diamond, Rank.king),
  ],
});

class ThemeScreen extends ConsumerWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize'),
      ),
      body: TwoPane(
        primaryBuilder: (context) => _buildTablePreview(context),
        secondaryBuilder: (context) => const _SettingsList(),
        stackingStyleOnPortrait: StackingStyle.topDown,
      ),
    );
  }

  Widget _buildTablePreview(BuildContext context) {
    final theme = SolitaireTheme.of(context);

    return AnimatedContainer(
      duration: themeChangeAnimation.duration,
      curve: themeChangeAnimation.curve,
      decoration: BoxDecoration(
        color: theme.backgroundColor,
      ),
      padding: const EdgeInsets.all(24) +
          EdgeInsets.only(left: MediaQuery.of(context).viewPadding.left),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
          child: GameTable(
            layout: _sampleLayout,
            table: _samplePlayTable,
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

    final themeMode = ref.watch(themeBaseModeProvider);
    final themeColor = ref.watch(themeBaseColorProvider);

    final randomizeColor = ref.watch(themeBaseRandomizeColorProvider);
    final coloredBackground = ref.watch(themeBackgroundColoredProvider);
    final amoledDarkTheme = ref.watch(themeBackgroundAmoledProvider);

    return Center(
      child: SizedBox(
        width: 600,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          children: [
            const SectionTitle('Overall', first: true),
            ListTile(
              title: const Text('Theme mode'),
              subtitle: const Text('Select light or dark mode'),
              trailing: Wrap(
                spacing: 8,
                children: [
                  IconButton.filled(
                    tooltip: 'Auto (follow system)',
                    isSelected: themeMode == ThemeMode.system,
                    color: themeMode == ThemeMode.system
                        ? colorScheme.onPrimary
                        : colorScheme.primary,
                    onPressed: () {
                      ref
                          .read(themeBaseModeProvider.notifier)
                          .set(ThemeMode.system);
                    },
                    icon: const Icon(Icons.brightness_auto),
                  ),
                  IconButton.filled(
                    tooltip: 'Light',
                    isSelected: themeMode == ThemeMode.light,
                    color: themeMode == ThemeMode.light
                        ? colorScheme.onPrimary
                        : colorScheme.primary,
                    onPressed: () {
                      ref
                          .read(themeBaseModeProvider.notifier)
                          .set(ThemeMode.light);
                    },
                    icon: const Icon(Icons.light_mode),
                  ),
                  IconButton.filled(
                    tooltip: 'Dark',
                    isSelected: themeMode == ThemeMode.dark,
                    color: themeMode == ThemeMode.dark
                        ? colorScheme.onPrimary
                        : colorScheme.primary,
                    onPressed: () {
                      ref
                          .read(themeBaseModeProvider.notifier)
                          .set(ThemeMode.dark);
                    },
                    icon: const Icon(Icons.dark_mode),
                  )
                ],
              ),
            ),
            // subtitle: Padding(
            //   padding: const EdgeInsets.only(top: 8),
            //   child: SegmentedButton<ThemeMode>(
            //     segments: const [
            //       ButtonSegment(
            //         value: ThemeMode.system,
            //         label: Text('System'),
            //         icon: Icon(Icons.brightness_6),
            //       ),
            //       ButtonSegment(
            //         value: ThemeMode.light,
            //         label: Text('Light'),
            //         icon: Icon(Icons.light_mode),
            //       ),
            //       ButtonSegment(
            //         value: ThemeMode.dark,
            //         label: Text('Dark'),
            //         icon: Icon(Icons.dark_mode),
            //       ),
            //     ],
            //     selected: {themeMode},
            //     onSelectionChanged: (value) {
            //       ref.read(themeBaseModeProvider.notifier).set(value.single);
            //     },
            //   ),
            // ),
            ListTile(
              title: const Text('Select colors'),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Material(
                  color: colorScheme.surfaceTint.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
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
                                .read(themeBaseRandomizeColorProvider.notifier)
                                .set(true);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      _ColorSelectionTile(
                        value: randomizeColor ? null : themeColor,
                        options: themeColorPalette,
                        onTap: (color) {
                          if (randomizeColor) {
                            ref
                                .read(themeBaseRandomizeColorProvider.notifier)
                                .set(false);
                          }
                          ref.read(themeBaseColorProvider.notifier).set(color);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SectionTitle('Background'),
            SwitchListTile(
              title: const Text('AMOLED dark background'),
              subtitle:
                  const Text('Use pitch black background when on dark mode'),
              value: amoledDarkTheme,
              onChanged: !coloredBackground && themeMode != ThemeMode.light
                  ? (value) {
                      ref.read(themeBackgroundAmoledProvider.notifier).toggle();
                    }
                  : null,
            ),
            SwitchListTile(
              title: const Text('Colored table background'),
              subtitle: const Text(
                  'Use strong colors of the theme for the table background'),
              value: coloredBackground,
              onChanged: (value) {
                ref.read(themeBackgroundColoredProvider.notifier).toggle();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSelectionTile extends StatelessWidget {
  const _ColorSelectionTile({
    super.key,
    required this.value,
    required this.options,
    required this.onTap,
  });

  final Color? value;

  final List<Color> options;

  final Function(Color) onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Wrap(
        alignment: WrapAlignment.start,
        children: [
          for (final color in themeColorPalette)
            IconButton(
              onPressed: () => onTap(color),
              isSelected: color.value == value?.value,
              iconSize: 32,
              icon: const Icon(Icons.circle_outlined),
              selectedIcon: const Icon(Icons.circle),
              color: color,
            ),
        ],
      ),
    );
  }
}
