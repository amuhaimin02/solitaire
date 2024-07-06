import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../providers/game_logic.dart';
import '../../../utils/types.dart';

class FinishDialog extends ConsumerWidget {
  const FinishDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final scoreSummary =
        ref.watch(gameControllerProvider.notifier).getScoreSummary();

    final isVegasScoring = scoreSummary.scoring.vegasScoring;

    String getScoreText(int score) {
      if (isVegasScoring) {
        return '\$ $score';
      } else {
        return '$score';
      }
    }

    Widget buildScoreText(int score,
        {required TextStyle style, String prefix = ''}) {
      if (isVegasScoring) {
        return Text.rich(
          TextSpan(children: [
            TextSpan(text: prefix),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(MdiIcons.currencyUsd, color: style.color),
            ),
            TextSpan(text: '$score'),
          ]),
          style: style,
        );
      } else {
        return Text('$prefix$score', style: style);
      }
    }

    return AlertDialog(
      title: const Text('You win!'),
      titleTextStyle:
          textTheme.headlineSmall!.copyWith(color: colorScheme.primary),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      content: SizedBox(
        width: 300,
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            primary: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  title: Row(
                    children: [
                      Text('Moves: ${scoreSummary.moves}'),
                      const Spacer(),
                      Text(
                          'Time: ${scoreSummary.playTime.toSimpleHMSString()}'),
                    ],
                  ),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Obtained'),
                  subtitle: const Text('Score during play'),
                  trailing: buildScoreText(
                    scoreSummary.obtainedScore,
                    style: textTheme.titleLarge!
                        .copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ),
                if (scoreSummary.hasBonus)
                  ListTile(
                    title: const Text('Bonus'),
                    trailing: buildScoreText(
                      scoreSummary.bonusScore,
                      style: textTheme.titleLarge!
                          .copyWith(color: colorScheme.onSurfaceVariant),
                      prefix: '+',
                    ),
                  ),
                if (scoreSummary.hasPenalty)
                  ListTile(
                    title: const Text('Penalty'),
                    trailing: buildScoreText(
                      scoreSummary.penaltyScore,
                      prefix: '−',
                      style: textTheme.titleLarge!
                          .copyWith(color: colorScheme.error),
                    ),
                  ),
                const Divider(),
                ListTile(
                  title: const Text('Final score'),
                  trailing: buildScoreText(
                    scoreSummary.finalScore,
                    style: textTheme.headlineMedium!
                        .copyWith(color: colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        FilledButton.tonal(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
          child: const Text('Play again'),
        ),
      ],
    );
  }
}
