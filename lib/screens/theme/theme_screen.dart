import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../animations.dart';
import '../../models/game/impl/demo.dart';
import '../../providers/themes.dart';
import '../../services/play_table_generator.dart';
import '../../widgets/bottom_padded.dart';
import '../../widgets/section_title.dart';
import '../../widgets/solitaire_theme.dart';
import '../../widgets/two_pane.dart';
import '../main/widgets/game_table.dart';
import 'widgets/color_selection_tile.dart';

class ThemeScreen extends ConsumerWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize'),
        scrolledUnderElevation: 0,
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

    // Using any random source we could find, but consistent across states
    // i.e., only changing when going in or out of this screen
    final randomSeed = context.hashCode.toString();

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
            game: SolitaireDemo(),
            table: PlayTableGenerator.generateSampleSetup(
                SolitaireDemo(), randomSeed),
            interactive: false,
            animateMovement: true,
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
          padding: const EdgeInsets.symmetric(vertical: 24) +
              BottomPadded.getPadding(context),
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
            ListTile(
              title: const Text('Select colors'),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Material(
                  color: colorScheme.surfaceTint.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.hardEdge,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Random color'),
                          secondary: const Icon(Icons.shuffle),
                          subtitle: const Text(
                              'Change color when starting a new game'),
                          value: randomizeColor,
                          onChanged: (value) {
                            ref
                                .read(themeBaseRandomizeColorProvider.notifier)
                                .toggle();
                          },
                        ),
                        const SizedBox(height: 8),
                        ColorSelectionTile(
                          value: themeColor,
                          options: themeColorPalette,
                          onTap: (color) {
                            ref
                                .read(themeBaseColorProvider.notifier)
                                .set(color);
                          },
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
            const SectionTitle('Cards'),
            SwitchListTile(
              title: const Text('Classic card colors'),
              subtitle: const Text(
                  'Use standard red-black labels with white background.'),
              value: ref.watch(themeUseClassicCardColorsProvider),
              onChanged: (value) {
                ref.read(themeUseClassicCardColorsProvider.notifier).toggle();
              },
            ),
            SwitchListTile(
              title: const Text('Compress card stack'),
              subtitle: const Text(
                  'Reduce the spacing of face-down cards in the stack.'),
              value: ref.watch(themeCompressCardStackProvider),
              onChanged: (value) {
                ref.read(themeCompressCardStackProvider.notifier).toggle();
              },
            ),
          ],
        ),
      ),
    );
  }
}
