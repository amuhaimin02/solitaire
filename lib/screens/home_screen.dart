import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../animations.dart';
import '../models/pile.dart';
import '../models/play_table.dart';
import '../providers/game_selection.dart';
import '../providers/game_storage.dart';
import '../providers/themes.dart';
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
                                child: Container(
                                  padding: const EdgeInsets.all(16.0),
                                  margin: const EdgeInsets.all(32.0),
                                  width: 800,
                                  decoration: BoxDecoration(
                                    color: SolitaireTheme.of(context)
                                        .tableBackgroundColor,
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  child:
                                      _GameSelection(orientation: orientation),
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 320,
                          child: AnimatedSwitcher(
                            duration: standardAnimation.duration,
                            child: (dropdownOpened)
                                ? const _GameVariantSelection()
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _GameVariantDropdown(),
                                      _GameControls(),
                                    ],
                                  ),
                          ),
                        ),
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
                                        child: Container(
                                          color: SolitaireTheme.of(context)
                                              .tableBackgroundColor,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 24),
                                          child: _GameSelection(
                                            orientation: orientation,
                                          ),
                                        ),
                                      ),
                                      const _GameControls(),
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

    return Text(
      selectedGame.name,
      style: textTheme.displayMedium!.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
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

    return FastPageView(
      itemCount: gamesNameList.length,
      itemBuilder: (context, index) {
        PlayTable table = PlayTable.fromGame(selectedGame)
            .modify(const Draw(), selectedGame.prepareDrawPile(Random(1)));
        table = selectedGame.setup(table);

        return GameTable(
          key: ValueKey(index),
          interactive: false,
          animateMovement: false,
          rules: selectedGame,
          orientation: orientation,
          table: table,
        );
      },
      onPageChanged: (index) {
        final nextGame = gamesCollection[gamesNameList[index]]!.first;
        ref.read(selectedGameProvider.notifier).select(nextGame);
      },
    );
  }
}

class _GameVariantDropdown extends ConsumerWidget {
  const _GameVariantDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGame = ref.watch(selectedGameProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          if (selectedGame.hasVariants)
            ActionChip(
              label: Text(selectedGame.variant.name),
              avatar: const Icon(Icons.keyboard_arrow_down),
              iconTheme: IconThemeData(color: colorScheme.onSurface),
              onPressed: () {
                ref.read(gameSelectionDropdownProvider.notifier).open();
              },
            ),
          ActionChip(
            label: const Text('How to play?'),
            iconTheme: IconThemeData(color: colorScheme.onSurface),
            avatar: const Icon(Icons.library_books),
            onPressed: () {
              final game = ref.read(selectedGameProvider);
              ref.read(gameStorageProvider.notifier).deleteQuickSave(game);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Save game deleted')));
            },
          )
        ],
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
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
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

class _GameControls extends ConsumerWidget {
  const _GameControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGame = ref.watch(selectedGameProvider);
    final hasQuickSave = ref.watch(hasQuickSaveProvider(selectedGame)).value;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasQuickSave != false)
            FilledButton.icon(
              onPressed: () async {
                try {
                  final game = ref.read(selectedGameProvider);
                  final gameData = await ref
                      .read(gameStorageProvider.notifier)
                      .restoreQuickSave(game);
                  if (!context.mounted) return;
                  Navigator.pushNamed(context, '/game', arguments: gameData);
                } catch (e) {
                  if (!context.mounted) return;
                  final response = await showDialog<bool>(
                    context: context,
                    builder: (_) => const _ContinueGameCorruptedDialog(),
                  );
                  if (response == true) {
                    if (!context.mounted) return;
                    final game = ref.read(selectedGameProvider);
                    Navigator.pushNamed(context, '/game', arguments: game);
                  }
                }
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 56),
              ),
              label: const Text('Continue last game'),
              icon: Icon(MdiIcons.cardsPlaying),
            ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () async {
              if (hasQuickSave == true) {
                final response = await showDialog<bool>(
                  context: context,
                  builder: (_) => const _NewGameDialog(),
                );
                if (response != true) return;
              }
              ref
                  .read(themeBaseRandomizeColorProvider.notifier)
                  .tryShuffleColor();
              final game = ref.read(selectedGameProvider);
              if (!context.mounted) return;
              Navigator.pushNamed(context, '/game', arguments: game);
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 56),
            ),
            label: const Text('New game'),
            icon: Icon(MdiIcons.cardsPlaying),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/stats');
                },
                tooltip: 'Statistics',
                icon: const Icon(Icons.leaderboard),
              ),
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/theme');
                },
                tooltip: 'Customize',
                icon: const Icon(Icons.imagesearch_roller),
              ),
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
                tooltip: 'Settings',
                icon: const Icon(Icons.settings),
              ),
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/about');
                },
                tooltip: 'About',
                icon: const Icon(Icons.info),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _NewGameDialog extends StatelessWidget {
  const _NewGameDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return DialogThemeFix(
      child: AlertDialog(
        title: const Text('Start new game?'),
        content: const Text(
            'There is a saved game available. Delete it and start a new one?'),
        actions: [
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('New game'),
          ),
        ],
      ),
    );
  }
}

class _ContinueGameCorruptedDialog extends StatelessWidget {
  const _ContinueGameCorruptedDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return DialogThemeFix(
      child: AlertDialog(
        title: const Text('Cannot continue game'),
        content: const Text(
            'Failed to load game as data might be corrupted. Start a new game instead?'),
        actions: [
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('New game'),
          ),
        ],
      ),
    );
  }
}

// TODO: Temporary workaround to fix dialog theme when using Google Fonts
class DialogThemeFix extends StatelessWidget {
  const DialogThemeFix({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Theme(
      data: Theme.of(context).copyWith(
        dialogTheme: DialogTheme(
          titleTextStyle: textTheme.headlineSmall!
              .copyWith(color: colorScheme.onPrimaryContainer),
          contentTextStyle: textTheme.bodyMedium!
              .copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ),
      child: child,
    );
  }
}
