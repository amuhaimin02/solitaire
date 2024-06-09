import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/game_logic.dart';
import '../../../utils/types.dart';
import '../../../widgets/fixes.dart';

class FinishDialog extends ConsumerWidget {
  const FinishDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final scoreSummary =
        ref.watch(gameControllerProvider.notifier).getScoreSummary();

    return DialogThemeFix(
      child: AlertDialog(
        title: const Text('You win'),
        content: SizedBox(
          width: 300,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text('Moves: ${scoreSummary.moves}'),
                    const Spacer(),
                    Text('Time: ${scoreSummary.playTime.toMMSSString()}'),
                  ],
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
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
                  contentPadding: EdgeInsets.zero,
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
                  contentPadding: EdgeInsets.zero,
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
                  contentPadding: EdgeInsets.zero,
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
      ),
    );
  }
}
