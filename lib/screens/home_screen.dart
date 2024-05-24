import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart' hide Consumer;
import '../animations.dart';
import '../models/game_selection_state.dart';
import '../models/pile.dart';
import '../providers/game_selection.dart';
import '../providers/settings.dart';
import '../utils/widgets.dart';
import '../widgets/fast_page_view.dart';
import '../widgets/game_table.dart';
import '../widgets/solitaire_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final orientation = constraints.biggest.aspectRatio > 1.33
                ? Orientation.landscape
                : Orientation.portrait;

            return Consumer(
              builder: (context, ref, child) {
                final dropdownOpened = ref.watch(gameSelectionDropdownProvider);

                switch (orientation) {
                  case Orientation.landscape:
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 7,
                          child: Column(
                            children: [
                              const Spacer(),
                              const Padding(
                                padding: EdgeInsets.all(32),
                                child: _GameTitle(),
                              ),
                              Expanded(
                                flex: 6,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child:
                                      _GameSelection(orientation: orientation),
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: AnimatedSwitcher(
                            duration: standardAnimation.duration,
                            child: (dropdownOpened)
                                ? const _GameVariantSelection()
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _GameVariantDropdown(),
                                      _GameMenu(),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(width: 32)
                      ],
                    );
                  case Orientation.portrait:
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: _GameTitle(),
                          ),
                        ),
                        Expanded(
                          flex: 10,
                          child: AnimatedSwitcher(
                            duration: standardAnimation.duration,
                            child: (dropdownOpened)
                                ? const Align(
                                    alignment: Alignment.topCenter,
                                    child: _GameVariantSelection(),
                                  )
                                : Column(
                                    children: [
                                      const _GameVariantDropdown(),
                                      Expanded(
                                        child: _GameSelection(
                                            orientation: orientation),
                                      ),
                                      const _GameMenu(),
                                      const SizedBox(height: 48),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    );
                }
              },
            );
          },
        ),
      ),
    );
  }
}

class _GameTitle extends ConsumerWidget {
  const _GameTitle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final selectedGame = ref.watch(selectedGameProvider);

    return ShaderMask(
      shaderCallback: (rect) {
        return LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect);
      },
      child: Text(
        selectedGame.name,
        style: textTheme.displayMedium!.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _GameSelection extends ConsumerWidget {
  const _GameSelection({super.key, required this.orientation});

  final Orientation orientation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGame = ref.watch(selectedGameProvider);

    final gamesCollection = ref.watch(allSolitaireGamesMappedProvider);
    final gamesNameList = gamesCollection.keys.toList();

    return SizedBox(
      width: 800,
      child: FastPageView(
        itemCount: gamesNameList.length,
        itemBuilder: (context, index) {
          final cards =
              PlayCards.fromGame(gamesCollection[gamesNameList[index]]!.first);
          cards(const Draw())
              .addAll(selectedGame.prepareDrawPile(Random(index)).allFaceDown);
          selectedGame.setup(cards);
          return GameTable(
            key: ValueKey(index),
            interactive: false,
            animateMovement: false,
            rules: selectedGame,
            orientation: orientation,
            cards: cards,
          );
        },
        onPageChanged: (index) {
          final nextGame = gamesCollection[gamesNameList[index]]!.first;
          ref.read(selectedGameProvider.notifier).select(nextGame);
        },
      ),
    );
  }
}

class _GameVariantDropdown extends ConsumerWidget {
  const _GameVariantDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGame = ref.watch(selectedGameProvider);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Visibility(
        visible: selectedGame.hasVariants,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.only(
                left: 16, right: 8), // Restore visual balance
          ),
          iconAlignment: IconAlignment.end,
          label: selectedGame.hasVariants
              ? Text(selectedGame.variant.name)
              : const Text("(no variant)"),
          icon: const Icon(Icons.arrow_drop_down),
          onPressed: selectedGame.hasVariants
              ? () {
                  ref.read(gameSelectionDropdownProvider.notifier).open();
                }
              : null,
        ),
      ),
    );
  }
}

class _GameVariantSelection extends ConsumerWidget {
  const _GameVariantSelection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGame = ref.watch(selectedGameProvider);
    final alternateVariants = ref.watch(selectedGameAlternateVariantsProvider);

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              'Select variant',
              style: textTheme.titleLarge!
                  .copyWith(color: colorScheme.onPrimaryContainer),
              textAlign: TextAlign.center,
            ),
          ),
          ...[
            for (final v in alternateVariants)
              ChoiceChip(
                label: Text(v.variant.name),
                selected: selectedGame.variant == v.variant,
                onSelected: (_) {
                  ref.read(selectedGameProvider.notifier).select(v);
                  ref.read(gameSelectionDropdownProvider.notifier).close();
                },
              ),
          ].separatedBy(const SizedBox(height: 8)),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _GameMenu extends StatelessWidget {
  const _GameMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.tonalIcon(
            onPressed: () {
              if (context
                  .read<SettingsManager>()
                  .get(Settings.randomizeThemeColor)) {
                context.read<SettingsManager>().set(
                    Settings.themeColor, themeColorPalette.sample(1).single);
              }

              final selection = context.read<GameSelectionState>();
              Navigator.pushNamed(context, '/game',
                  arguments: selection.selectedRules);
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 56),
            ),
            label: const Text('New game'),
            icon: Icon(MdiIcons.cardsPlaying),
          ),
          const SizedBox(height: 8),
          Visibility(
            visible: true,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: FilledButton.icon(
              onPressed: () {
                final selection = context.read<GameSelectionState>();
                Navigator.pushNamed(context, '/game',
                    arguments: selection.selectedRules);
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 56),
              ),
              label: const Text('Continue last game'),
              icon: Icon(MdiIcons.cardsPlaying),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              IconButton(
                onPressed: () {},
                tooltip: "Help",
                icon: const Icon(Icons.help),
              ),
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/stats');
                },
                tooltip: "Statistics",
                icon: const Icon(Icons.leaderboard),
              ),
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/customize');
                },
                tooltip: "Customize",
                icon: const Icon(Icons.imagesearch_roller),
              ),
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
                tooltip: "Settings",
                icon: const Icon(Icons.settings),
              ),
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/about');
                },
                tooltip: "About",
                icon: const Icon(Icons.info),
              ),
            ],
          )
        ],
      ),
    );
  }
}
