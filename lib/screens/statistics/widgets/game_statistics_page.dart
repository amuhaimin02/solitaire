import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

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
      appBar: TwoPane.of(context).isActive ? null : AppBar(),
      body: ListView(
        children: [
          GameStatisticsInsights(game: selectedGame),
          buildDisplayModeSelection(),
          if (statsItem is AsyncData)
            for (final (index, item) in statsItem.value!.indexed)
              GameStatisticsListTile(index: index, entry: item)
          else if (statsItem.hasError)
            // TODO: Temporary
            Text(statsItem.error.toString())
          else
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
