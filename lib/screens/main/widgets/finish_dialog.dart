import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                      Text('Time: ${scoreSummary.playTime.toMMSSString()}'),
                    ],
                  ),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Obtained'),
                  subtitle: const Text('Score during play'),
                  trailing: Text(
                    '${scoreSummary.obtainedScore}',
                    style: textTheme.titleLarge!
                        .copyWith(color: colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.end,
                  ),
                ),
                ListTile(
                  title: const Text('Bonus'),
                  subtitle: const Text('700,000 / play seconds'),
                  trailing: Text(
                    '+${scoreSummary.bonusScore}',
                    style: textTheme.titleLarge!
                        .copyWith(color: colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.end,
                  ),
                ),
                ListTile(
                  title: const Text('Penalty'),
                  subtitle: const Text('2 points every 10 seconds'),
                  trailing: Text(
                    '-${scoreSummary.penaltyScore}',
                    style: textTheme.titleLarge!
                        .copyWith(color: colorScheme.error),
                    textAlign: TextAlign.end,
                  ),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Final score'),
                  trailing: Text(
                    '${scoreSummary.finalScore}',
                    style: textTheme.headlineMedium!
                        .copyWith(color: colorScheme.primary),
                    textAlign: TextAlign.end,
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
