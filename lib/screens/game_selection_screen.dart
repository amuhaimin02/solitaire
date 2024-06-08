import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../animations.dart';
import '../models/game/solitaire.dart';
import '../providers/game_logic.dart';
import '../providers/game_selection.dart';
import '../providers/game_storage.dart';
import '../providers/settings.dart';
import '../services/play_table_generator.dart';
import '../utils/prng.dart';
import '../utils/types.dart';
import '../utils/widgets.dart';
import '../widgets/bottom_padded.dart';
import '../widgets/empty_screen.dart';
import '../widgets/game_table.dart';
import '../widgets/popup_button.dart';
import '../widgets/solitaire_theme.dart';
import '../widgets/two_pane.dart';

class GameSelectionScreen extends ConsumerStatefulWidget {
  const GameSelectionScreen({super.key});

  @override
  ConsumerState<GameSelectionScreen> createState() =>
      _GameSelectionScreenState();
}

class _GameSelectionScreenState extends ConsumerState<GameSelectionScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(selectedGameProvider.notifier).deselect();
    });
  }

  @override
  Widget build(BuildContext context) {
    return TwoPane(
      primaryBuilder: (context) => const _GameSelectionList(),
      secondaryBuilder: (context) => const _GameSelectionDetail(),
      stackingStyleOnPortrait: StackingStyle.bottomSheet,
    );
  }
}

class _GameSelectionList extends ConsumerWidget {
  const _GameSelectionList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solitaire games'),
        actions: [
          IconButton(
            tooltip: 'Search',
            onPressed: () {},
            icon: const Icon(Icons.search),
          ),
          const _GameSelectionActions(),
        ],
      ),
      body: Builder(
        builder: (context) {
          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const TabBar.secondary(
                  tabs: [
                    Tab(text: 'Favorites'),
                    Tab(text: 'Continue'),
                    Tab(text: 'All games'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildFavoriteGameList(context, ref),
                      _buildContinueGameList(context, ref),
                      _buildAllGamesList(context, ref),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFavoriteGameList(BuildContext context, WidgetRef ref) {
    final selectedGame = ref.watch(selectedGameProvider);
    final favoritedGames = ref.watch(favoritedGamesProvider);

    if (favoritedGames.isEmpty) {
      return const EmptyScreen(
        icon: Icon(Icons.favorite_border),
        title: Text('No favorited games yet'),
        body: Text(
            'Find the games you liked on All games tab and add it to favorite to see them here'),
      );
    } else {
      return ListView(
        key: const PageStorageKey('favorite'),
        padding: BottomPadded.getPadding(context),
        children: [
          for (final game in favoritedGames)
            _GameListTile(
              selected: TwoPane.of(context).isActive && selectedGame == game,
              game: game,
              onTap: () => _onListTap(context, ref, game),
            ),
        ],
      );
    }
  }

  Widget _buildContinueGameList(BuildContext context, WidgetRef ref) {
    final selectedGame = ref.watch(selectedGameProvider);
    final continuableGames = ref.watch(continuableGamesProvider);

    if (continuableGames.isLoading) {
      return const Align(
        alignment: Alignment.topCenter,
        child: LinearProgressIndicator(),
      );
    }

    if (continuableGames.value == null || continuableGames.value!.isEmpty) {
      return const EmptyScreen(
        icon: Icon(Icons.favorite_border),
        title: Text('No games to continue'),
        body: Text(
            'Play some games and you may continue your unfinished game here'),
      );
    } else {
      return ListView(
        key: const PageStorageKey('continue'),
        padding: BottomPadded.getPadding(context),
        children: [
          for (final game in continuableGames.value!)
            _GameListTile(
              selected: TwoPane.of(context).isActive && selectedGame == game,
              game: game,
              onTap: () => _onListTap(context, ref, game),
            ),
        ],
      );
    }
  }

  Widget _buildAllGamesList(BuildContext context, WidgetRef ref) {
    final allGamesMapped = ref.watch(allSolitaireGamesMappedProvider);
    final selectedGame = ref.watch(selectedGameProvider);
    return ListView(
      key: const PageStorageKey('all'),
      padding: BottomPadded.getPadding(context),
      children: [
        for (final (group, gameList) in allGamesMapped.items)
          _GameListGroup(
            key: PageStorageKey('all-$group'),
            groupName: group,
            children: [
              for (final game in gameList)
                _GameListTile(
                  selected:
                      TwoPane.of(context).isActive && selectedGame == game,
                  game: game,
                  onTap: () => _onListTap(context, ref, game),
                )
            ],
          ),
      ],
    );
  }

  void _onListTap(BuildContext context, WidgetRef ref, SolitaireGame game) {
    ref.read(selectedGameProvider.notifier).select(game);
    TwoPane.of(context).pushSecondary();
  }
}

class _GameListGroup extends StatelessWidget {
  const _GameListGroup(
      {super.key, required this.children, required this.groupName});

  final String groupName;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return ExpansionTile(
      leading: Icon(MdiIcons.cardsPlaying),
      title: Text(
        groupName,
        style: textTheme.titleLarge!.copyWith(color: colorScheme.primary),
      ),
      iconColor: colorScheme.primary,
      collapsedIconColor: colorScheme.primary,
      tilePadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: Border.all(color: Colors.transparent),
      collapsedShape: Border.all(color: Colors.transparent),
      backgroundColor: colorScheme.surfaceContainer,
      expansionAnimationStyle: AnimationStyle(
        curve: standardAnimation.curve,
        duration: standardAnimation.duration,
      ),
      children: children,
    );
  }
}

class _GameListTile extends ConsumerWidget {
  const _GameListTile({
    super.key,
    required this.game,
    this.onTap,
    this.selected = false,
  });

  final SolitaireGame game;

  final VoidCallback? onTap;

  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final continuableGames = ref.watch(continuableGamesProvider).value;

    return ListTile(
      selected: selected,
      selectedColor: colorScheme.onSecondaryContainer,
      selectedTileColor: colorScheme.secondaryContainer,
      leading: Icon(MdiIcons.cardsPlayingSpadeOutline),
      title: Text(game.name),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      trailing: Wrap(
        spacing: 12,
        children: [
          if (continuableGames != null && continuableGames.contains(game))
            Icon(MdiIcons.motionPauseOutline),
          if (ref.watch(favoritedGamesProvider).contains(game))
            const Icon(Icons.favorite),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _GameSelectionDetail extends ConsumerWidget {
  const _GameSelectionDetail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final selectedGame = ref.watch(selectedGameProvider);
    final randomSeed = CustomPRNG.generateSeed(length: 12);

    if (selectedGame == null) {
      return EmptyScreen(
        icon: Icon(MdiIcons.cardsPlaying),
        title: const Text('Select a game'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Material(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Builder(
                builder: (context) {
                  final isInModal = !TwoPane.of(context).isActive;

                  final gameTableWidget = Container(
                    color: SolitaireTheme.of(context).backgroundColor,
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: GameTable(
                        key: ValueKey(selectedGame),
                        game: selectedGame,
                        table: PlayTableGenerator.generateSampleSetup(
                          selectedGame,
                          randomSeed,
                        ),
                        orientation: isInModal
                            ? Orientation.portrait
                            : Orientation.landscape,
                        fitEmptySpaces: true,
                        animateDistribute: false,
                        animateMovement: false,
                        interactive: false,
                      ),
                    ),
                  );
                  if (isInModal) {
                    return gameTableWidget;
                  } else {
                    return Expanded(child: gameTableWidget);
                  }
                },
              ),
              ClipRect(
                clipBehavior: Clip.hardEdge,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        selectedGame.name,
                        style: textTheme.titleLarge!.copyWith(
                          color: colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Details of gameplay will be available here. '
                        'Details of gameplay will be available here. '
                        'Details of gameplay will be available here. '
                        'Details of gameplay will be available here. ',
                        style: textTheme.bodyMedium!.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 24),
                      _GameSelectionOptions(
                        singleLine: constraints.maxHeight <= 500,
                        game: selectedGame,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GameSelectionOptions extends ConsumerWidget {
  const _GameSelectionOptions(
      {super.key, required this.game, required this.singleLine});

  final bool singleLine;

  final SolitaireGame game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final continuableGames = ref.watch(continuableGamesProvider).value;

    final canContinueGame =
        continuableGames != null && continuableGames.contains(game);

    final Widget playButtonWidget;

    if (canContinueGame) {
      playButtonWidget = FilledButton.icon(
        icon: const Icon(Icons.play_circle),
        label: const Text('Continue last game'),
        onPressed: () async {
          TwoPane.of(context).popSecondary();
          Navigator.pop(context);
          ref.read(selectedGameProvider.notifier).select(game);
          ref.read(settingsLastPlayedGameProvider.notifier).set(game.tag);
          final gameData = await ref
              .read(gameStorageProvider.notifier)
              .restoreQuickSave(game);
          ref.read(gameControllerProvider.notifier).restore(gameData);
        },
      );
    } else {
      playButtonWidget = FilledButton.icon(
        icon: Icon(MdiIcons.cardsPlaying),
        label: const Text('Play game'),
        onPressed: () {
          TwoPane.of(context).popSecondary();
          Navigator.pop(context);
          ref.read(selectedGameProvider.notifier).select(game);
          ref.read(settingsLastPlayedGameProvider.notifier).set(game.tag);
          ref.read(gameControllerProvider.notifier).startNew(game);
        },
      );
    }

    final miscButtonWidgets = [
      if (ref.watch(favoritedGamesProvider).contains(game))
        FilledButton.tonalIcon(
          icon: const Icon(Icons.favorite),
          label: const Text('Added to favorites'),
          onPressed: () {
            ref.read(favoritedGamesProvider.notifier).removeFromFavorite(game);
          },
        )
      else
        FilledButton.tonalIcon(
          icon: const Icon(Icons.favorite_border),
          label: const Text('Add to favorites'),
          onPressed: () {
            ref.read(favoritedGamesProvider.notifier).addToFavorite(game);
          },
        ),
      FilledButton.tonalIcon(
        onPressed: () {},
        icon: const Icon(Icons.book),
        label: const Text('View rules'),
      ),
      FilledButton.tonalIcon(
        onPressed: () {},
        icon: Icon(MdiIcons.stepForward2),
        label: const Text('View demo'),
      ),
      FilledButton.tonalIcon(
        onPressed: () {
          context.go('/statistics');
        },
        icon: const Icon(Icons.leaderboard),
        label: const Text('Statistics'),
      ),
    ];

    return Column(
      children: [
        if (!singleLine) ...[
          SizedBox(
            height: 48,
            width: double.infinity,
            child: playButtonWidget,
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: EdgeInsets.zero,
            children: [
              if (singleLine) playButtonWidget,
              ...miscButtonWidgets,
            ].separatedBy(const SizedBox(width: 8)),
          ),
        )
      ],
    );
  }
}

class _GameSelectionActions extends ConsumerWidget {
  const _GameSelectionActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupButton(
      icon: const Icon(Icons.more_horiz),
      builder: (popupContext) {
        void dismiss() {
          Navigator.pop(popupContext);
        }

        return [
          ListTile(
            leading: Icon(MdiIcons.trayArrowDown),
            title: const Text('Import game'),
            onTap: () async {
              dismiss();

              try {
                final gameData = await ref
                    .read(gameStorageProvider.notifier)
                    .importQuickSave();
                if (gameData != null) {
                  ref.read(gameControllerProvider.notifier).restore(gameData);
                }
                // Go back to game screen once imported
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failure importing games.\n$e')),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: Icon(MdiIcons.trayArrowUp),
            title: const Text('Export game'),
            onTap: () async {
              dismiss();
              final gameData =
                  ref.read(gameControllerProvider.notifier).suspend();
              ref.read(gameStorageProvider.notifier).exportQuickSave(gameData);
            },
          ),
        ];
      },
    );
  }
}
