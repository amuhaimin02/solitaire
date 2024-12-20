import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/game/solitaire.dart';
import '../../../providers/game_selection.dart';
import '../../../providers/game_storage.dart';
import '../../../utils/types.dart';
import '../../../widgets/bottom_padded.dart';
import '../../../widgets/empty_message.dart';
import '../../../widgets/section_title.dart';
import '../../../widgets/two_pane.dart';
import 'game_list_group.dart';
import 'game_list_tile.dart';
import 'game_selection_actions.dart';

class GameSelectionList extends ConsumerWidget {
  const GameSelectionList({super.key, required this.onSearchButtonPressed});

  final VoidCallback onSearchButtonPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solitaire games'),
        actions: [
          IconButton(
            tooltip: 'Search',
            onPressed: onSearchButtonPressed,
            icon: const Icon(Icons.search),
          ),
          const GameSelectionActions(),
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
                    Tab(text: 'Featured'),
                    Tab(text: 'All games'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildFeaturedGameList(context, ref),
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

  Widget _buildFeaturedGameList(BuildContext context, WidgetRef ref) {
    final favoritedGames = ref.watch(favoritedGamesProvider);
    final continuableGames = ref.watch(continuableGamesProvider);

    return ListView(
      key: const PageStorageKey('featured'),
      padding: BottomPadded.getPadding(context),
      children: [
        const SectionTitle('Continue games', first: true),
        if (continuableGames.value?.isEmpty == true)
          const EmptyMessage(
            body: Text('No recent games'),
          )
        else
          for (final game
              in continuableGames.value?.take(5) ?? <SolitaireGame>[])
            GameListTile(
              game: game,
              onTap: () => _onListTap(context, ref, game),
            ),
        const SectionTitle('Favorites'),
        if (favoritedGames.isEmpty)
          const EmptyMessage(
            body: Text('No favorited games yet'),
          )
        else
          for (final game in favoritedGames)
            GameListTile(
              game: game,
              onTap: () => _onListTap(context, ref, game),
            ),
      ],
    );
  }

  Widget _buildAllGamesList(BuildContext context, WidgetRef ref) {
    final allGamesMapped = ref.watch(allSolitaireGamesMappedProvider);
    return ListView(
      key: const PageStorageKey('all'),
      padding: BottomPadded.getPadding(context),
      children: [
        for (final (group, gameList) in allGamesMapped.items)
          GameListGroup(
            key: PageStorageKey('all-$group'),
            groupName: group,
            children: [
              for (final game in gameList)
                GameListTile(
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
