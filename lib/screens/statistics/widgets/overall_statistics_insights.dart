import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/game_selection.dart';
import '../../../providers/statistics.dart';
import '../../../utils/types.dart';

class StatisticsInsights extends ConsumerWidget {
  const StatisticsInsights({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final totalPlayTime = ref.watch(statisticsTotalPlayTimeProvider);
    final totalGamesPlayed = ref.watch(statisticsTotalGamesPlayedProvider);
    final totalWins = ref.watch(statisticsTotalGamesWonProvider);
    final totalGameTypes = ref.watch(allSolitaireGamesProvider).length;
    final totalGameTypesPlayed =
        ref.watch(statisticsTotalGameTypesPlayedProvider);
    final totalGameTypeWins = ref.watch(statisticsTotalGameTypesWonProvider);

    final bodyTextStyle =
        textTheme.bodyMedium!.copyWith(color: colorScheme.onSurface);
    final playTimeTextStyle =
        textTheme.headlineLarge!.copyWith(color: colorScheme.primary);
    final numbersTextStyle =
        textTheme.titleLarge!.copyWith(color: colorScheme.primary);

    Widget buildTotalPlayTime() {
      return Text(
        totalPlayTime.toNaturalHMSString(),
        style: playTimeTextStyle,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: DefaultTextStyle(
        style: bodyTextStyle,
        child: Column(
          children: [
            Text('You have played for', style: bodyTextStyle),
            const SizedBox(height: 8),
            buildTotalPlayTime(),
            const SizedBox(height: 24),
            Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'Played  '),
                TextSpan(
                    text: totalGameTypesPlayed.toString(),
                    style: numbersTextStyle),
                const TextSpan(text: '  out of  '),
                TextSpan(
                    text: totalGameTypes.toString(), style: numbersTextStyle),
                const TextSpan(text: '  kinds of games'),
              ]),
            ),
            Text.rich(TextSpan(children: [
              const TextSpan(text: 'and won  '),
              TextSpan(
                  text: totalGameTypeWins.toString(), style: numbersTextStyle),
              const TextSpan(text: '  games at least once'),
            ])),
            const SizedBox(height: 24),
            Text.rich(TextSpan(children: [
              const TextSpan(text: 'Played a total of  '),
              TextSpan(
                  text: totalGamesPlayed.toString(), style: numbersTextStyle),
              const TextSpan(text: '  games'),
            ])),
            Text.rich(TextSpan(children: [
              const TextSpan(text: 'and won  '),
              TextSpan(text: totalWins.toString(), style: numbersTextStyle),
              const TextSpan(text: '  times'),
            ])),
          ],
        ),
      ),
    );
  }
}
