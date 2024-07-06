import 'package:flutter/material.dart';

import '../../../models/game/solitaire.dart';
import '../../../widgets/leveled_progress_bar.dart';

class GameStatisticsListTile<T extends num> extends StatelessWidget {
  const GameStatisticsListTile({
    super.key,
    required this.game,
    required this.valueLabelBuilder,
    required this.value,
    required this.secondaryValue,
    required this.maxRefValue,
    required this.onTap,
  });

  final SolitaireGame game;
  final Widget Function(BuildContext, T) valueLabelBuilder;
  final T value;
  final T? secondaryValue;
  final T maxRefValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(game.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          valueLabelBuilder(context, value),
          const SizedBox(height: 8),
          LeveledProgressBar(
            value: value / maxRefValue,
            secondaryValue:
                secondaryValue != null ? secondaryValue! / maxRefValue : null,
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
