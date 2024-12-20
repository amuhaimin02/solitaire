import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../animations.dart';
import '../../models/card.dart';
import '../../models/game/impl/demo.dart';
import '../../models/game_theme.dart';
import '../../providers/themes.dart';
import '../../services/all.dart';
import '../../services/play_table_generator.dart';
import '../../utils/types.dart';
import '../../widgets/bottom_padded.dart';
import '../../widgets/ripple_background.dart';
import '../../widgets/section_title.dart';
import '../../widgets/tiled_selection.dart';
import '../../widgets/two_pane.dart';
import '../main/widgets/card_back.dart';
import '../main/widgets/card_face.dart';
import '../main/widgets/game_table.dart';
import 'widgets/color_selection_tile.dart';

class ThemeScreen extends ConsumerWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RippleBackground(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Customize'),
          scrolledUnderElevation: 0,
        ),
        body: TwoPane(
          primaryBuilder: (context) => _buildTablePreview(context),
          secondaryBuilder: (context) => const _SettingsList(),
          stackingStyleOnPortrait: StackingStyle.topDown,
          primaryRatioOnPortrait: 0.4,
        ),
      ),
    );
  }

  Widget _buildTablePreview(BuildContext context) {
    // Using any random source we could find, but consistent across states
    // i.e., only changing when going in or out of this screen
    final randomSeed = context.hashCode.toString();

    return AnimatedContainer(
      duration: themeChangeAnimation.duration,
      curve: themeChangeAnimation.curve,
      decoration: Theme.of(context).gameTheme.getTableBackgroundDecoration(),
      padding: const EdgeInsets.all(24) +
          EdgeInsets.only(left: MediaQuery.of(context).viewPadding.left),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
          child: GameTable(
            game: SolitaireDemo(),
            table: svc<PlayTableGenerator>()
                .generateSampleSetup(SolitaireDemo(), randomSeed),
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
    final tableBackgroundStyle = ref.watch(themeTableBackgroundStyleProvider);
    final cardFaceStyle = ref.watch(themeCardFaceStyleProvider);
    final cardBackStyle = ref.watch(themeCardBackStyleProvider);
    final amoledDarkTheme = ref.watch(themeBackgroundAmoledProvider);

    Widget wrapCardTheme({
      CardFaceStyle? faceStyle,
      CardBackStyle? backStyle,
      required Widget child,
    }) {
      final gameCardTheme = Theme.of(context).gameCardTheme;

      return Theme(
        data: Theme.of(context).copyWith(extensions: [
          GameCardTheme.from(
            colorScheme: colorScheme,
            labelFontFamily: gameCardTheme.labelFontFamily,
            faceStyle: faceStyle ?? gameCardTheme.faceStyle,
            backStyle: backStyle ?? gameCardTheme.backStyle,
          )
        ]),
        child: child,
      );
    }

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
            ListTile(
              title: const Text('Background style'),
              subtitle: TiledSelection(
                items: [
                  for (final style in TableBackgroundStyle.values)
                    TiledSelectionItem(
                      value: style,
                      label: Text(style.name.capitalize()),
                      child: Container(
                        decoration: GameTheme.from(
                          colorScheme: colorScheme,
                          tableBackgroundStyle: style,
                        ).getTableBackgroundDecoration().copyWith(
                            border: Border.all(color: colorScheme.outline)),
                      ),
                    ),
                ],
                selected: tableBackgroundStyle,
                onSelectionChanged: (value) {
                  ref
                      .read(themeTableBackgroundStyleProvider.notifier)
                      .set(value);
                },
              ),
            ),
            SwitchListTile(
              title: const Text('AMOLED dark background'),
              subtitle:
                  const Text('Use pitch black background when on dark mode'),
              value: amoledDarkTheme,
              onChanged: themeMode != ThemeMode.light &&
                      tableBackgroundStyle == TableBackgroundStyle.simple
                  ? (value) {
                      ref.read(themeBackgroundAmoledProvider.notifier).toggle();
                    }
                  : null,
            ),
            const SectionTitle('Card'),
            ListTile(
              title: const Text('Card face'),
              subtitle: TiledSelection(
                items: [
                  for (final style in CardFaceStyle.values)
                    TiledSelectionItem(
                      value: style,
                      label: Text(style.name.capitalize()),
                      child: wrapCardTheme(
                        faceStyle: style,
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: CardFace(
                                card: const PlayCard(Rank.jack, Suit.spade),
                                labelAlignment: Alignment.center,
                                size: cardSizeRatio.scale(15),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: CardFace(
                                card: const PlayCard(Rank.ace, Suit.heart),
                                labelAlignment: Alignment.center,
                                size: cardSizeRatio.scale(15),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
                selected: cardFaceStyle,
                onSelectionChanged: (value) {
                  ref.read(themeCardFaceStyleProvider.notifier).set(value);
                },
              ),
            ),
            ListTile(
              title: const Text('Card back'),
              subtitle: TiledSelection(
                items: [
                  for (final style in CardBackStyle.values)
                    TiledSelectionItem(
                      value: style,
                      label: Text(style.name.capitalize()),
                      child: Center(
                        child: wrapCardTheme(
                          backStyle: style,
                          child: CardBack(
                            size: cardSizeRatio.scale(18),
                          ),
                        ),
                      ),
                    ),
                ],
                selected: cardBackStyle,
                onSelectionChanged: (value) {
                  ref.read(themeCardBackStyleProvider.notifier).set(value);
                },
              ),
            ),
            const SectionTitle('Arrangement'),
            SwitchListTile(
              title: const Text('Compact card stack'),
              subtitle: const Text('Reduce spacing of cards among the stack.'),
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
