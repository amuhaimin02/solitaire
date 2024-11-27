import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../models/game/solitaire.dart';
import '../../../providers/game_logic.dart';
import '../../../providers/game_selection.dart';
import '../../../providers/game_storage.dart';
import '../../../providers/settings.dart';
import '../../../utils/widgets.dart';
import '../../../widgets/two_pane.dart';
import 'continue_failed_dialog.dart';

class GameSelectionOptions extends ConsumerWidget {
  const GameSelectionOptions({
    super.key,
    required this.game,
    required this.singleLine,
  });

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
        icon: Icon(MdiIcons.motionPlayOutline),
        label: const Text('Continue last game'),
        onPressed: () async {
          _loadSavedGame(context, ref);
        },
      );
    } else {
      playButtonWidget = FilledButton.icon(
        icon: const Icon(Icons.play_circle_fill),
        label: const Text('Play game'),
        onPressed: () {
          _startNewGame(context, ref);
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

  void _loadSavedGame(BuildContext context, WidgetRef ref) async {
    try {
      ref.read(selectedGameProvider.notifier).select(game);
      ref.read(settingsLastPlayedGameProvider.notifier).set(game.tag);
      final gameData =
          await ref.read(gameStorageProvider.notifier).restoreQuickSave(game);
      ref.read(gameControllerProvider.notifier).restore(gameData);
      if (!context.mounted) return;
      TwoPane.of(context).popSecondary();
      Navigator.pop(context);
    } catch (error) {
      if (!context.mounted) return;
      final response = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ContinueFailedDialog(error: error),
      );
      if (response == true) {
        if (!context.mounted) return;
        _startNewGame(context, ref);
      } else {
        if (!context.mounted) return;
        TwoPane.of(context).popSecondary();
      }
    }
  }

  void _startNewGame(BuildContext context, WidgetRef ref) {
    ref.read(selectedGameProvider.notifier).select(game);
    ref.read(settingsLastPlayedGameProvider.notifier).set(game.tag);
    ref.read(gameControllerProvider.notifier).startNew(game);
    TwoPane.of(context).popSecondary();
    Navigator.pop(context);
  }
}
