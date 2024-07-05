import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/game/solitaire.dart';
import '../../../providers/game_logic.dart';
import '../../../providers/statistics.dart';
import '../../../utils/types.dart';

class GameStatisticsInsights extends ConsumerWidget {
  const GameStatisticsInsights({super.key, required this.game});

  final SolitaireGame game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final playTime = ref.watch(statisticsPlayTimeProvider(game));
    final games = ref.watch(statisticsGamesPlayedProvider(game));
    final wins = ref.watch(statisticsGamesWonProvider(game));
    final winPercentage = games > 0 ? wins / games * 100 : 0;

    Widget buildStatsItem(String value, String label) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style:
                textTheme.headlineLarge!.copyWith(color: colorScheme.primary),
          ),
          Text(
            label,
            style: textTheme.labelLarge!.copyWith(color: colorScheme.onSurface),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.name,
                  style: textTheme.headlineSmall!
                      .copyWith(color: colorScheme.onSurface),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 24,
                  children: [
                    buildStatsItem(games.toString(), 'Games'),
                    buildStatsItem(wins.toString(), 'Wins'),
                    buildStatsItem(
                        playTime.toNaturalHMSString(), 'Total play time'),
                  ],
                )
              ],
            ),
          ),
          SizedBox.square(
            dimension: 144,
            child: Container(
              decoration: ShapeDecoration(
                shape: CircleBorder(
                  side: BorderSide(width: 12, color: colorScheme.primary),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${winPercentage.toStringAsFixed(2)}%',
                        style: textTheme.headlineMedium!
                            .copyWith(color: colorScheme.primary),
                      ),
                      Text(
                        'Win rate',
                        style: textTheme.labelLarge!
                            .copyWith(color: colorScheme.onSurface),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
