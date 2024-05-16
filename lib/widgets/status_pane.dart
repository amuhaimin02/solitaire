import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../utils/types.dart';

class StatusPane extends StatelessWidget {
  const StatusPane({super.key, required this.orientation});

  final Orientation orientation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final divider = SizedBox(
      height: 24,
      child: VerticalDivider(
        color: colorScheme.onPrimaryContainer.withOpacity(0.3),
      ),
    );

    return switch (orientation) {
      Orientation.landscape => const Column(
          children: [
            ScoreLabel(),
            SizedBox(height: 8),
            TimeLabel(),
            MoveLabel(),
          ],
        ),
      Orientation.portrait => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(child: Center(child: TimeLabel())),
            divider,
            const Expanded(child: Center(child: ScoreLabel())),
            divider,
            const Expanded(child: Center(child: MoveLabel())),
          ],
        ),
    };
  }
}

class TimeLabel extends StatelessWidget {
  const TimeLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme.onPrimaryContainer;

    return StreamBuilder<Null>(
      stream: Stream.periodic(const Duration(milliseconds: 200)),
      builder: (context, snapshot) {
        final playTime = context.read<GameState>().playTime;
        return Text(
          playTime.toMMSSString(),
          style: textTheme.bodyLarge!.copyWith(color: color),
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
    final color = Theme.of(context).colorScheme.onPrimaryContainer;
    final score = context.select<GameState, int>((s) => s.score);
    return Text(
      '$score',
      style: textTheme.displayMedium!.copyWith(color: color),
    );
  }
}

class MoveLabel extends StatelessWidget {
  const MoveLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme.onPrimaryContainer;

    final moves = context.select<GameState, int>((s) => s.moves);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$moves',
          style: textTheme.bodyLarge!.copyWith(color: color),
        ),
        const SizedBox(width: 8),
        Icon(MdiIcons.cards, color: color, size: 18),
      ],
    );
  }
}
