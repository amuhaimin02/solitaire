import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/game/solitaire.dart';
import '../../../providers/game_selection.dart';
import '../../../providers/statistics.dart';
import '../../../utils/types.dart';
import '../../../widgets/popup_button.dart';
import '../models/statistics_display_mode.dart';
import 'game_statistics_list_tile.dart';
import 'statistics_insights.dart';

class OverallStatistics extends ConsumerStatefulWidget {
  const OverallStatistics({super.key});

  @override
  ConsumerState<OverallStatistics> createState() => _OverallStatisticsState();
}

class _OverallStatisticsState extends ConsumerState<OverallStatistics> {
  StatisticsDisplayMode _displayMode = StatisticsDisplayMode.wins;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    num getPrimaryStatsValue(SolitaireGame game) {
      switch (_displayMode) {
        case StatisticsDisplayMode.playTime:
          return ref.watch(statisticsPlayTimeProvider(game)).inMilliseconds;
        case StatisticsDisplayMode.gamesAndWins:
          return ref.watch(statisticsGamesPlayedProvider(game));
        case StatisticsDisplayMode.wins:
          return ref.watch(statisticsGamesWonProvider(game));
      }
    }

    num? getSecondaryStatsValue(SolitaireGame game) {
      switch (_displayMode) {
        case StatisticsDisplayMode.gamesAndWins:
          return ref.watch(statisticsGamesWonProvider(game));
        default:
          return null;
      }
    }

    final allGames = ref.watch(allSolitaireGamesProvider);

    final collectedPrimaryStatsValues = <SolitaireGame, num>{
      for (final game in allGames) game: getPrimaryStatsValue(game),
    };
    final collectedSecondaryStatsValues = <SolitaireGame, num?>{
      for (final game in allGames) game: getSecondaryStatsValue(game),
    };

    final maxPrimaryStatsValue =
        collectedPrimaryStatsValues.values.toList().max;

    Widget buildValueLabel(SolitaireGame game, num value) {
      switch (_displayMode) {
        case StatisticsDisplayMode.playTime:
          final duration = Duration(milliseconds: value as int);
          return Text(duration.toNaturalHMSString());
        case StatisticsDisplayMode.gamesAndWins:
          final wins = collectedSecondaryStatsValues[game] ?? 0;
          final winPercentage = wins / value * 100;
          return Text(
              '$value games, $wins wins (${winPercentage.toStringAsFixed(2)} %)');
        case StatisticsDisplayMode.wins:
          return Text('$value wins');
      }
    }

    Widget buildSortButton() {
      return PopupButton(
        icon: const Icon(Icons.sort),
        builder: (context) {
          void dismiss() => Navigator.pop(context);

          return [
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Import game'),
              onTap: () => setState(() {
                _displayMode = StatisticsDisplayMode.playTime;
                dismiss();
              }),
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Games and wins'),
              onTap: () => setState(() {
                _displayMode = StatisticsDisplayMode.gamesAndWins;
                dismiss();
              }),
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Wins'),
              onTap: () => setState(() {
                _displayMode = StatisticsDisplayMode.wins;
                dismiss();
              }),
            ),
          ];
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: ListView(
        children: [
          const StatisticsInsights(),
          const Divider(),
          ListTile(
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Sorted by: ${_displayMode.label}',
                    style: textTheme.bodyLarge),
                buildSortButton(),
              ],
            ),
          ),
          for (final entry in collectedPrimaryStatsValues.entries
              .sortedBy((e) => e.value)
              .reversed
              .where((e) => e.value > 0))
            GameStatisticsListTile(
              game: entry.key,
              value: entry.value,
              secondaryValue: collectedSecondaryStatsValues[entry.key],
              valueLabelBuilder: (_, value) =>
                  buildValueLabel(entry.key, value),
              maxRefValue: maxPrimaryStatsValue,
            ),
        ],
      ),
    );
  }
}
