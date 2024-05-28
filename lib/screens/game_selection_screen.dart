import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../animations.dart';

class GameSelectionScreen extends ConsumerWidget {
  const GameSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Solitaire games'),
      ),
      body: ListView(
        children: [
          for (int i = 0; i < 12; i++)
            ExpansionTile(
              leading: Icon(MdiIcons.cardsPlaying),
              initiallyExpanded: i == 3,
              title: Text(
                'Klondike',
                style:
                    textTheme.titleLarge!.copyWith(color: colorScheme.primary),
              ),
              iconColor: colorScheme.primary,
              collapsedIconColor: colorScheme.primary,
              tilePadding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              shape: Border.all(color: Colors.transparent),
              collapsedShape: Border.all(color: Colors.transparent),
              backgroundColor: colorScheme.surfaceContainer,
              expansionAnimationStyle: AnimationStyle(
                curve: standardAnimation.curve,
                duration: standardAnimation.duration,
              ),
              children: [
                ListTile(
                  selected: i == 3,
                  selectedColor: colorScheme.onSecondary,
                  selectedTileColor: colorScheme.secondary,
                  leading: Icon(MdiIcons.cardsPlayingSpadeOutline),
                  title: const Text('Klondike 1 draw'),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  trailing: Wrap(
                    spacing: 0,
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.play_arrow),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.leaderboard),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.favorite_border),
                      ),
                    ],
                  ),
                  onTap: () {},
                ),
                ListTile(
                  leading: Icon(MdiIcons.cardsPlayingSpadeOutline),
                  title: const Text('Klondike 2 draws'),
                  onTap: () {},
                ),
                ListTile(
                  leading: Icon(MdiIcons.cardsPlayingSpadeOutline),
                  title: const Text('Klondike 3 draws'),
                  onTap: () {},
                )
              ],
            ),
        ],
      ),
    );
  }
}
