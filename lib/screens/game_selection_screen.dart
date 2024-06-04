import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:xrandom/xrandom.dart';

import '../animations.dart';
import '../models/game/solitaire.dart';
import '../providers/game_logic.dart';
import '../providers/game_selection.dart';
import '../services/play_table_generator.dart';
import '../utils/prng.dart';
import '../utils/widgets.dart';
import '../widgets/empty_screen.dart';
import '../widgets/game_table.dart';
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
          )
        ],
      ),
      body: Builder(
        builder: (context) {
          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar.secondary(
                  tabs: [
                    Tab(text: 'Favorites'),
                    Tab(text: 'All games'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildFavoriteGameList(context, ref),
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

  Widget _buildAllGamesList(BuildContext context, WidgetRef ref) {
    final allGamesMapped = ref.watch(allSolitaireGamesMappedProvider);
    final selectedGame = ref.watch(selectedGameProvider);
    return ListView(
      key: const PageStorageKey('all'),
      children: [
        for (final group in allGamesMapped.entries)
          _GameListGroup(
            key: PageStorageKey('all-${group.key}'),
            groupName: group.key,
            children: [
              for (final game in group.value)
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
    final currentGame = ref.watch(currentGameProvider);

    return ListTile(
      selected: selected,
      selectedColor: colorScheme.secondary,
      selectedTileColor: colorScheme.secondaryContainer,
      leading: currentGame.game == game
          ? const Icon(Icons.play_circle)
          : Icon(MdiIcons.cardsPlayingSpadeOutline),
      title: Text(game.name),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      trailing: Wrap(
        spacing: 12,
        children: [
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
    final playButtonWidget = FilledButton.icon(
      icon: const Icon(Icons.play_circle),
      label: const Text('Play game'),
      onPressed: () {
        TwoPane.of(context).popSecondary();
        Navigator.pop(context);
        ref.read(selectedGameProvider.notifier).select(game);
        ref.read(gameControllerProvider.notifier).startNew(game);
      },
    );

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
