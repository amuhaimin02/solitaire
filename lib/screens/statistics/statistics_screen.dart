import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/game_selection.dart';
import '../../providers/statistics.dart';
import '../../widgets/section_title.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to any change of statistics and update when necessary
    ref.watch(statisticsUpdaterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Total play time'),
            subtitle:
                Text(ref.watch(statisticsTotalPlayTimeProvider).toString()),
          ),
          ListTile(
            title: const Text('Total games played'),
            subtitle:
                Text(ref.watch(statisticsTotalGamesPlayedProvider).toString()),
          ),
          for (final game in ref.watch(allSolitaireGamesProvider)) ...[
            SectionTitle(game.name),
            ListTile(
              title: const Text('Play time'),
              subtitle:
                  Text(ref.watch(statisticsPlayTimeProvider(game)).toString()),
            ),
            ListTile(
              title: const Text('Games'),
              subtitle: Text(
                  ref.watch(statisticsGamesPlayedProvider(game)).toString()),
            ),
            ListTile(
              title: const Text('Win percentage'),
              subtitle: Text(ref
                  .watch(statisticsGamesWinPercentageProvider(game))
                  .toString()),
            ),
          ]
        ],
      ),
    );
  }
}
