import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../utils/types.dart';
import 'solitaire_theme.dart';

class StatusPane extends StatelessWidget {
  const StatusPane({super.key, required this.orientation});

  final Orientation orientation;

  @override
  Widget build(BuildContext context) {
    final theme = SolitaireTheme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTextStyle.merge(
      style: Theme.of(context)
          .textTheme
          .titleLarge!
          .copyWith(color: colorScheme.primary),
      child: switch (orientation) {
        Orientation.landscape => const Column(
            children: [
              ScoreLabel(),
              SizedBox(height: 8),
              TimeLabel(),
              MoveLabel(),
            ],
          ),
        Orientation.portrait => const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Center(child: TimeLabel())),
              SizedBox(
                height: 24,
                child: VerticalDivider(),
              ),
              Expanded(child: Center(child: ScoreLabel())),
              SizedBox(
                height: 24,
                child: VerticalDivider(),
              ),
              Expanded(child: Center(child: MoveLabel())),
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

    return StreamBuilder<Null>(
      stream: Stream.periodic(const Duration(milliseconds: 200)),
      builder: (context, snapshot) {
        final playTime = context.read<GameState>().playTime;
        return Text(
          playTime.toMMSSString(),
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
    final textStyle =
        score >= 10000 ? textTheme.displaySmall! : textTheme.displayMedium!;
    return Text(
      '$score',
      style: textStyle.copyWith(color: colorScheme.primary),
      textAlign: TextAlign.center,
    );
  }
}

class MoveLabel extends StatelessWidget {
  const MoveLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final moves = context.select<GameState, int>((s) => s.moves);
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
