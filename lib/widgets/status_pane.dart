import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../utils/types.dart';

class StatusPane extends StatelessWidget {
  const StatusPane({super.key, required this.orientation});

  final Orientation orientation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: switch (orientation) {
        Orientation.landscape => const Column(
            children: [
              MoveLabel(),
              ScoreLabel(),
              TimeLabel(),
            ],
          ),
        Orientation.portrait => const Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: MoveLabel()),
              ScoreLabel(),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TimeLabel(),
                ),
              ),
            ],
          ),
      },
    );
  }
}

class TimeLabel extends StatelessWidget {
  const TimeLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<Null>(
      stream: Stream.periodic(const Duration(milliseconds: 200)),
      builder: (context, snapshot) {
        final playTime = context.read<GameState>().playTime;
        return Text(
          playTime.toMMSSString(),
          style: textTheme.bodyLarge!
              .copyWith(color: colorScheme.onSecondaryContainer),
        );
      },
    );
  }
}

class ScoreLabel extends StatelessWidget {
  const ScoreLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final score = context.select<GameState, int>((s) => s.score);
    return Text(
      '$score',
      style: textTheme.displaySmall!
          .copyWith(color: colorScheme.onSecondaryContainer),
    );
  }
}

class MoveLabel extends StatelessWidget {
  const MoveLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final moves = context.select<GameState, int>((s) => s.moves);
    return Text(
      'Move: $moves',
      style: textTheme.bodyLarge!
          .copyWith(color: colorScheme.onSecondaryContainer),
    );
  }
}
