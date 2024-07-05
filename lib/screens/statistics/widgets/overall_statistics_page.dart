import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../models/game/solitaire.dart';
import '../../../providers/game_selection.dart';
import '../../../providers/statistics.dart';
import '../../../utils/types.dart';
import '../../../widgets/overlay_button.dart';
import '../../../widgets/two_pane.dart';
import '../models/statistics_display_mode.dart';
import 'overall_statistics_list_tile.dart';
import 'overall_statistics_insights.dart';

class OverallStatisticsPage extends ConsumerStatefulWidget {
  const OverallStatisticsPage({super.key});

  @override
  ConsumerState<OverallStatisticsPage> createState() =>
      _OverallStatisticsState();
}

class _OverallStatisticsState extends ConsumerState<OverallStatisticsPage> {
  OverallStatisticsDisplayMode _displayMode =
      OverallStatisticsDisplayMode.gamesAndWins;

  @override
  Widget build(BuildContext context) {
    num getPrimaryStatsValue(SolitaireGame game) {
      switch (_displayMode) {
        case OverallStatisticsDisplayMode.playTime:
          return ref.watch(statisticsPlayTimeProvider(game)).inMilliseconds;
        case OverallStatisticsDisplayMode.gamesAndWins:
          return ref.watch(statisticsGamesPlayedProvider(game));
        case OverallStatisticsDisplayMode.wins:
          return ref.watch(statisticsGamesWonProvider(game));
      }
    }

    num? getSecondaryStatsValue(SolitaireGame game) {
      switch (_displayMode) {
        case OverallStatisticsDisplayMode.gamesAndWins:
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
        case OverallStatisticsDisplayMode.playTime:
          final duration = Duration(milliseconds: value as int);
          return Text(duration.toNaturalHMSString());
        case OverallStatisticsDisplayMode.gamesAndWins:
          final wins = collectedSecondaryStatsValues[game] ?? 0;
          final winPercentage = value > 0 ? wins / value * 100 : 0;
          return Text(
              '$value games, $wins wins (${winPercentage.toStringAsFixed(2)} %)');
        case OverallStatisticsDisplayMode.wins:
          return Text('$value wins');
      }
    }

    String getDisplayModeLabel(OverallStatisticsDisplayMode mode) {
      return switch (mode) {
        OverallStatisticsDisplayMode.gamesAndWins => 'Games & wins',
        OverallStatisticsDisplayMode.wins => 'Wins',
        OverallStatisticsDisplayMode.playTime => 'Play time',
      };
    }

    IconData getDisplayModeIcon(OverallStatisticsDisplayMode mode) {
      return switch (mode) {
        OverallStatisticsDisplayMode.gamesAndWins => MdiIcons.cardsPlaying,
        OverallStatisticsDisplayMode.wins => MdiIcons.partyPopper,
        OverallStatisticsDisplayMode.playTime => MdiIcons.clockOutline,
      };
    }

    Widget buildSortButton() {
      return OverlayButton(
        buttonBuilder: (context, trigger) {
          return OutlinedButton.icon(
            icon: const Icon(Icons.sort),
            onPressed: trigger,
            label: Text('Sort: ${getDisplayModeLabel(_displayMode)}'),
          );
        },
        overlayBuilder: (context) {
          void dismiss() => Navigator.pop(context);

          return [
            for (final mode in OverallStatisticsDisplayMode.values)
              ListTile(
                leading: Icon(getDisplayModeIcon(mode)),
                title: Text(getDisplayModeLabel(mode)),
                onTap: () => setState(() {
                  _displayMode = mode;
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
                buildSortButton(),
              ],
            ),
          ),
          for (final entry in collectedPrimaryStatsValues.entries
              .sortedBy((e) => e.value)
              .reversed)
            GameStatisticsListTile(
              game: entry.key,
              value: entry.value,
              secondaryValue: collectedSecondaryStatsValues[entry.key],
              valueLabelBuilder: (_, value) =>
                  buildValueLabel(entry.key, value),
              maxRefValue: maxPrimaryStatsValue,
              onTap: () {
                ref.read(selectedGameProvider.notifier).select(entry.key);
                TwoPane.of(context).pushSecondary();
              },
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
