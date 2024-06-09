import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../animations.dart';
import '../../../models/user_action.dart';
import '../../../providers/game_logic.dart';

class UserActionIndicator extends ConsumerWidget {
  const UserActionIndicator({super.key});

  static const userActionIcon = {
    UserActionOptions.undoMultiple: Icons.fast_rewind,
    UserActionOptions.redoMultiple: Icons.fast_forward,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    final userAction = ref.watch(userActionProvider);

    return AnimatedSwitcher(
      duration: cardMoveAnimation.duration,
      child: userAction != null
          ? Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: colorScheme.inverseSurface,
              ),
              child: Icon(
                userActionIcon[userAction],
                size: 72,
                color: colorScheme.onInverseSurface,
              ),
            )
          : null,
    );
  }
}
