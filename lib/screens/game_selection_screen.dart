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

class GameSelectionScreen extends ConsumerStatefulWidget {
  const GameSelectionScreen({super.key});

  @override
  ConsumerState<GameSelectionScreen> createState() =>
      _GameSelectionScreenState();
}

class _GameSelectionScreenState extends ConsumerState<GameSelectionScreen> {
  late final _scrollController = ScrollController();

  // Ensure autoscroll is done once. This variable will be the flag
  bool _autoScrolled = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final splitView = orientation == Orientation.landscape;

    if (splitView) {
      return Row(
        children: [
          Expanded(
            child: _GameSelectionList(
              asSplitView: splitView,
            ),
          ),
          Expanded(
            child: _GameSelectionDetail(
              game: ref.watch(selectedGameProvider),
              asSplitView: splitView,
            ),
          ),
        ],
      );
    } else {
      return _GameSelectionList(asSplitView: splitView);
    }
  }
  //
  // void _scrollToSelection(BuildContext context) {
  //   Future.microtask(() {
  //     final itemBound = context.globalPaintBounds;
  //     final screenSize = MediaQuery.of(context).size;
  //
  //     if (itemBound != null) {
  //       _scrollController.jumpTo(itemBound.center.dy - screenSize.height / 2);
  //       _autoScrolled = true;
  //     }
  //   });
  // }
}

class _GameSelectionList extends ConsumerWidget {
  const _GameSelectionList({super.key, required this.asSplitView});

  final bool asSplitView;

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
      body: Builder(builder: (context) {
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
      }),
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
              selected: asSplitView && selectedGame == game,
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
              selected: asSplitView && selectedGame == game,
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
                  selected: asSplitView && selectedGame == game,
                  game: game,
                  onTap: () => _onListTap(context, ref, game),
                )
            ],
          ),
      ],
    );
  }

  void _onListTap(BuildContext context, WidgetRef ref, SolitaireGame game) {
    if (!asSplitView) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => _GameSelectionDetail(
          asSplitView: asSplitView,
          game: game,
        ),
      );
    } else {
      ref.read(selectedGameProvider.notifier).select(game);
    }
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
  const _GameSelectionDetail(
      {super.key, required this.asSplitView, required this.game});

  final bool asSplitView;

  final SolitaireGame game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Builder(
            builder: (context) {
              final gameTableWidget = Container(
                color: SolitaireTheme.of(context).tableBackgroundColor,
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: GameTable(
                    key: ValueKey(game),
                    layout: game.getLayout(
                      TableLayoutOptions(
                        orientation: asSplitView
                            ? Orientation.landscape
                            : Orientation.portrait,
                        mirror: false,
                      ),
                    ),
                    table: game.generateRandomSetup(),
                    fitEmptySpaces: true,
                    animateDistribute: false,
                    animateMovement: false,
                    interactive: false,
                  ),
                ),
              );
              if (asSplitView) {
                return Expanded(child: gameTableWidget);
              } else {
                return gameTableWidget;
              }
            },
          ),
          Container(
            color: colorScheme.surfaceContainerLow,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  game.name,
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
          Container(
            color: colorScheme.surfaceContainerLowest,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.play_circle),
                      label: const Text('Play game'),
                      onPressed: () {
                        if (!asSplitView) {
                          // Dismiss this screen as it was opened as a modal
                          Navigator.pop(context);
                        }
                        Navigator.pop(context);

                        ref.read(selectedGameProvider.notifier).select(game);
                        ref
                            .read(gameControllerProvider.notifier)
                            .startNew(game);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      children: [
                        if (ref.watch(favoritedGamesProvider).contains(game))
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.favorite),
                            label: const Text('Added to favorites'),
                            onPressed: () {
                              ref
                                  .read(favoritedGamesProvider.notifier)
                                  .removeFromFavorite(game);
                            },
                          )
                        else
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.favorite_border),
                            label: const Text('Add to favorites'),
                            onPressed: () {
                              ref
                                  .read(favoritedGamesProvider.notifier)
                                  .addToFavorite(game);
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
                            ref
                                .read(gameStorageProvider.notifier)
                                .deleteQuickSave(game);
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text('Delete last save'),
                        ),
                      ].separatedBy(const SizedBox(width: 8)),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
