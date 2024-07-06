import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../models/game/solitaire.dart';
import '../../../providers/game_selection.dart';
import '../../../providers/statistics.dart';
import '../../../widgets/empty_message.dart';
import '../../../widgets/two_pane.dart';
import '../models/statistics_display_mode.dart';
import 'game_statistics_insights.dart';
import 'game_statistics_list_tile.dart';

class GameStatisticsPage extends ConsumerStatefulWidget {
  const GameStatisticsPage({super.key});

  @override
  ConsumerState<GameStatisticsPage> createState() => _GameStatisticsPageState();
}

class _GameStatisticsPageState extends ConsumerState<GameStatisticsPage> {
  GameStatisticsType _displayType = GameStatisticsType.highScore;

  @override
  Widget build(BuildContext context) {
    final selectedGame = ref.watch(selectedGameProvider);

    if (selectedGame == null) {
      return EmptyMessage(
        icon: Icon(MdiIcons.cardsPlaying),
        title: const Text('Select a game'),
      );
    }

    Widget buildDisplayModeSelection() {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: SegmentedButton<GameStatisticsType>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: GameStatisticsType.highScore,
              icon: Icon(Icons.leaderboard),
              label: Text('High scores'),
            ),
            ButtonSegment(
              value: GameStatisticsType.recent,
              icon: Icon(Icons.access_time),
              label: Text('Recent'),
            )
          ],
          selected: {_displayType},
          onSelectionChanged: (selection) {
            setState(() {
              _displayType = selection.single;
            });
          },
        ),
      );
    }

    final statsItem =
        ref.watch(statisticsForGameProvider(selectedGame, _displayType));

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !TwoPane.of(context).isActive,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Clear statistics',
            onPressed: () => _onDeletePressed(context, selectedGame),
          )
        ],
      ),
      body: ListView(
        children: [
          GameStatisticsInsights(game: selectedGame),
          buildDisplayModeSelection(),
          if (statsItem.hasValue)
            if (statsItem.value!.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60.0),
                child: EmptyMessage(
                  icon: Icon(Icons.leaderboard),
                  title: Text('No records yet'),
                ),
              )
            else
              for (final (index, item) in statsItem.value!.indexed)
                GameStatisticsListTile(
                  index: index,
                  entry: item,
                  showIndex: _displayType == GameStatisticsType.highScore,
                )
          else if (statsItem.hasError)
            // TODO: Temporary
            Text(statsItem.error.toString())
        ],
      ),
    );
  }

  Future<void> _onDeletePressed(
      BuildContext context, SolitaireGame game) async {
    final colorScheme = Theme.of(context).colorScheme;

    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear statistics?'),
        content: Text(
            'Are you sure to clear and reset statistics for ${game.name}? This will remove all records associated with this game.'),
        actions: [
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          )
        ],
      ),
    );

    if (confirm == true) {
      await ref
          .read(statisticsUpdaterProvider.notifier)
          .clearGameStatistics(game);
    }
  }
}
