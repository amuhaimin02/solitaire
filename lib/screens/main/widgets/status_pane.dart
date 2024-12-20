import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../providers/game_logic.dart';
import '../../../providers/game_move_history.dart';
import '../../../providers/settings.dart';
import '../../../utils/types.dart';
import '../../../utils/widgets.dart';

class StatusPane extends ConsumerWidget {
  const StatusPane({super.key, required this.orientation});

  final Orientation orientation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    final showMoves = ref.watch(settingsShowMoveCountProvider);
    final showTime = ref.watch(settingsShowPlayTimeProvider);
    final showScore = ref.watch(settingsShowScoreProvider);

    return DefaultTextStyle.merge(
      style: Theme.of(context)
          .textTheme
          .titleLarge!
          .copyWith(color: colorScheme.onSurface),
      child: switch (orientation) {
        Orientation.landscape => Column(
            children: [
              if (showScore) const ScoreLabel(),
              if (showTime) const TimeLabel(),
              if (showMoves) const MoveLabel(),
            ],
          ),
        Orientation.portrait => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showTime) const Expanded(child: Center(child: TimeLabel())),
              if (showScore) const Expanded(child: Center(child: ScoreLabel())),
              if (showMoves) const Expanded(child: Center(child: MoveLabel())),
            ].separatedBy(SizedBox(
              height: 24,
              child: VerticalDivider(color: colorScheme.onSurface),
            )),
          ),
      },
    );
  }
}

class TimeLabel extends ConsumerWidget {
  const TimeLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: StreamBuilder<Null>(
        stream: ref.watch(playTimeIsRunningProvider)
            ? Stream.periodic(const Duration(milliseconds: 200))
            : const Stream.empty(),
        builder: (context, snapshot) {
          final playTime = ref.read(playTimeProvider);
          ref.invalidate(playTimeProvider);
          return Text(playTime.toSimpleHMSString());
        },
      ),
    );
  }
}

class ScoreLabel extends ConsumerWidget {
  const ScoreLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final isVegasScoring = ref.watch(
        currentGameProvider.select((game) => game.kind.scoring.vegasScoring));

    final score = ref.watch(currentScoreProvider);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: isVegasScoring
          ? Container(
              decoration: ShapeDecoration(
                color: colorScheme.secondary,
                shape: const StadiumBorder(),
              ),
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    MdiIcons.currencyUsd,
                    size: 32,
                    color: colorScheme.onSecondary,
                  ),
                  Text(
                    '${score ?? 0}',
                    style: textTheme.headlineLarge!
                        .copyWith(color: colorScheme.onSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : Text(
              '${score ?? 0}',
              style: textTheme.displayMedium!
                  .copyWith(color: colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
    );
  }
}

class MoveLabel extends ConsumerWidget {
  const MoveLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moves = ref.watch(currentMoveNumberProvider);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${moves ?? 0}'),
          const SizedBox(width: 8),
          Icon(MdiIcons.cards,
              size: 18, color: DefaultTextStyle.of(context).style.color),
        ],
      ),
    );
  }
}
