import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../providers/game_logic.dart';
import '../providers/settings.dart';
import '../utils/types.dart';
import '../utils/widgets.dart';

class StatusPane extends ConsumerWidget {
  const StatusPane({super.key, required this.orientation});

  final Orientation orientation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    final showMoves = ref.watch(showMovesProvider);
    final showTime = ref.watch(showTimeProvider);
    final showScore = ref.watch(showScoreProvider);

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
            ].separatedBy(const SizedBox(
              height: 24,
              child: VerticalDivider(),
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
    return StreamBuilder<Null>(
      stream: Stream.periodic(const Duration(milliseconds: 200)),
      builder: (context, snapshot) {
        final playTime = ref.read(playTimeProvider);
        return Text(playTime.toMMSSString());
      },
    );
  }
}

class ScoreLabel extends ConsumerWidget {
  const ScoreLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final score = ref.watch(scoreProvider);

    final textStyle =
        score >= 10000 ? textTheme.displaySmall! : textTheme.displayMedium!;
    return Text(
      '$score',
      style: textStyle.copyWith(color: colorScheme.onSurface),
      textAlign: TextAlign.center,
    );
  }
}

class MoveLabel extends ConsumerWidget {
  const MoveLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moves = ref.watch(moveCountProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$moves'),
        const SizedBox(width: 8),
        Icon(MdiIcons.cards,
            size: 18, color: DefaultTextStyle.of(context).style.color),
      ],
    );
  }
}
