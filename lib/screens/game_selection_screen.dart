import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../animations.dart';
import '../providers/game_logic.dart';
import '../providers/game_selection.dart';
import '../widgets/popup_button.dart';

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
      body: switch (orientation) {
        Orientation.landscape => const Row(
            children: [
              Expanded(child: _GameSelectionList()),
              Expanded(child: _GameSelectionDetail()),
            ],
          ),
        Orientation.portrait => const _GameSelectionList(),
      },
    );
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
  const _GameSelectionList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final allGames = ref.watch(allSolitaireGamesMappedProvider);
    final currentGame = ref.watch(currentGameProvider).rules;

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
                for (int i = 0; i < 3; i++)
                  ListView(
                    // controller: _scrollController,
                    children: [
                      for (final family in allGames.keys)
                        ExpansionTile(
                          leading: Icon(MdiIcons.cardsPlaying),
                          initiallyExpanded: currentGame.family == family,
                          title: Text(
                            family,
                            style: textTheme.titleLarge!
                                .copyWith(color: colorScheme.primary),
                          ),
                          iconColor: colorScheme.primary,
                          collapsedIconColor: colorScheme.primary,
                          tilePadding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          shape: Border.all(color: Colors.transparent),
                          collapsedShape: Border.all(color: Colors.transparent),
                          backgroundColor: colorScheme.surfaceContainer,
                          expansionAnimationStyle: AnimationStyle(
                            curve: standardAnimation.curve,
                            duration: standardAnimation.duration,
                          ),
                          children: [
                            for (final game in allGames[family]!)
                              Builder(
                                builder: (context) {
                                  // if (currentGame == game && !_autoScrolled) {
                                  //   _scrollToSelection(context);
                                  // }
                                  return ListTile(
                                    selected: currentGame == game,
                                    selectedColor: colorScheme.onSecondary,
                                    selectedTileColor: colorScheme.secondary,
                                    leading:
                                        Icon(MdiIcons.cardsPlayingSpadeOutline),
                                    title: Text(game.name),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    trailing: Wrap(
                                      spacing: 0,
                                      children: [
                                        PopupButton(
                                          icon: const Icon(Icons.play_arrow),
                                          builder: (context, dismiss) {
                                            return [
                                              for (int i = 0; i < 10; i++)
                                                const ListTile(
                                                  title: Text('Test 1'),
                                                )
                                            ];
                                          },
                                        ),
                                        IconButton(
                                          onPressed: () {},
                                          icon: const Icon(Icons.leaderboard),
                                        ),
                                        IconButton(
                                          onPressed: () {},
                                          icon:
                                              const Icon(Icons.favorite_border),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      ref
                                          .read(selectedGameProvider.notifier)
                                          .select(game);
                                      ref
                                          .read(gameControllerProvider.notifier)
                                          .startNew(game);
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              ),
                          ],
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GameSelectionDetail extends StatelessWidget {
  const _GameSelectionDetail({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            MdiIcons.cardsPlaying,
            size: 72,
            color: colorScheme.secondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Select a game',
            style: textTheme.bodyLarge!.copyWith(color: colorScheme.secondary),
          ),
        ],
      ),
    );
  }
}
