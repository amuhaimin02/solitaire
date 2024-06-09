import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/game_status.dart';
import '../../../providers/game_logic.dart';
import '../../../widgets/shrinkable.dart';

class AutoSolveButton extends ConsumerWidget {
  const AutoSolveButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoSolvable = ref.watch(autoSolvableProvider);
    final gameStatus = ref.watch(gameControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Shrinkable(
      show: autoSolvable && gameStatus == GameStatus.started,
      child: FloatingActionButton.extended(
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
        onPressed: () {
          ref.read(gameControllerProvider.notifier).autoSolve();
        },
        icon: const Icon(Icons.auto_fix_high),
        label: const Text('Auto solve'),
      ),
    );
  }
}
