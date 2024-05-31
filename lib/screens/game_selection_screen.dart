import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../animations.dart';
import '../models/game/solitaire.dart';
import '../models/table_layout.dart';
import '../providers/game_logic.dart';
import '../providers/game_selection.dart';
import '../providers/game_storage.dart';
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
            length: 3,
            child: PageStorage(
              bucket: PageStorageBucket(),
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

  Widget _buildContinueGameList(BuildContext context, WidgetRef ref) {
    final selectedGame = ref.watch(selectedGameProvider);
    final continuableGames = ref.watch(continuableGamesProvider);

    if (continuableGames.isEmpty) {
      return const EmptyScreen(
        icon: Icon(Icons.play_circle),
        title: Text('No pending games yet'),
        body: Text(
            'Game that you have played and not finished yet will be listed here'),
      );
    } else {
      return ListView(
        key: const PageStorageKey('continue'),
        children: [
          for (final game in continuableGames)
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
            key: const PageStorageKey('all'),
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
      leading: Icon(MdiIcons.cardsPlayingSpadeOutline),
      title: Text(game.name),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      trailing: Wrap(
        spacing: 12,
        children: [
          if (currentGame.game == game)
            const Icon(Icons.play_circle)
          else if (ref.watch(continuableGamesProvider).contains(game))
            const Icon(Icons.play_arrow),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        print(constraints);
        return Material(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Builder(
                builder: (context) {
                  final gameTableWidget = Container(
                    color: SolitaireTheme.of(context).backgroundColor,
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: GameTable(
                        key: ValueKey(selectedGame),
                        layout: selectedGame.getLayout(
                          TableLayoutOptions(
                            orientation: TwoPane.of(context).isActive
                                ? Orientation.landscape
                                : Orientation.portrait,
                            mirror: false,
                          ),
                        ),
                        table: selectedGame.generateRandomSetup(),
                        fitEmptySpaces: true,
                        animateDistribute: false,
                        animateMovement: false,
                        interactive: false,
                      ),
                    ),
                  );
                  if (TwoPane.of(context).isActive) {
                    return Expanded(child: gameTableWidget);
                  } else {
                    return gameTableWidget;
                  }
                },
              ),
              Container(
                color: colorScheme.surfaceContainerLow,
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      selectedGame.name,
                      style: textTheme.headlineSmall!.copyWith(
                        color: colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Details of gameplay will be available here',
                      style: textTheme.bodyLarge!.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    )
                  ],
                ),
              ),
              _GameSelectionOptions(
                singleLine: constraints.maxHeight <= 500,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GameSelectionOptions extends ConsumerWidget {
  const _GameSelectionOptions({super.key, required this.singleLine});

  final bool singleLine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedGame = ref.watch(selectedGameProvider);

    final playButtonWidget = FilledButton.icon(
      icon: const Icon(Icons.play_circle),
      label: const Text('Play game'),
      onPressed: () {
        TwoPane.of(context).popSecondary();
        Navigator.pop(context);
        ref.read(selectedGameProvider.notifier).select(selectedGame);
        ref.read(gameControllerProvider.notifier).startNew(selectedGame);
      },
    );

    final miscButtonWidgets = [
      if (ref.watch(favoritedGamesProvider).contains(selectedGame))
        FilledButton.tonalIcon(
          icon: const Icon(Icons.favorite),
          label: const Text('Added to favorites'),
          onPressed: () {
            ref
                .read(favoritedGamesProvider.notifier)
                .removeFromFavorite(selectedGame);
          },
        )
      else
        FilledButton.tonalIcon(
          icon: const Icon(Icons.favorite_border),
          label: const Text('Add to favorites'),
          onPressed: () {
            ref
                .read(favoritedGamesProvider.notifier)
                .addToFavorite(selectedGame);
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
      FilledButton.tonalIcon(
        onPressed: () {
          ref.read(gameStorageProvider.notifier).deleteQuickSave(selectedGame);
        },
        icon: const Icon(Icons.delete),
        label: const Text('Delete last save'),
      ),
    ];

    return ClipRect(
      clipBehavior: Clip.hardEdge,
      child: Container(
        color: colorScheme.surfaceContainerLowest,
        padding: const EdgeInsets.all(16),
        child: Column(
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
                children: [
                  if (singleLine) playButtonWidget,
                  ...miscButtonWidgets,
                ].separatedBy(const SizedBox(width: 8)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
