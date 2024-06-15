import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../models/game/solitaire.dart';
import '../../../providers/game_selection.dart';
import '../../../providers/game_storage.dart';
import '../../../widgets/two_pane.dart';

class GameListTile extends ConsumerWidget {
  const GameListTile({
    super.key,
    required this.game,
    this.onTap,
  });

  final SolitaireGame game;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final continuableGames = ref.watch(continuableGamesProvider).value;
    final selectedGame = ref.watch(selectedGameProvider);

    return ListTile(
      selected: TwoPane.of(context).isActive ? selectedGame == game : false,
      selectedColor: colorScheme.onPrimaryContainer,
      selectedTileColor: colorScheme.primaryContainer,
      leading: Icon(MdiIcons.cardsPlayingSpadeOutline),
      title: Text(game.name),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      trailing: Wrap(
        spacing: 12,
        children: [
          if (ref.watch(favoritedGamesProvider).contains(game))
            const Icon(Icons.favorite),
          if (continuableGames != null && continuableGames.contains(game))
            Icon(MdiIcons.motionPauseOutline),
        ],
      ),
      onTap: onTap,
    );
  }
}
