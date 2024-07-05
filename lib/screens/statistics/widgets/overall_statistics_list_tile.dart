import 'package:flutter/material.dart';

import '../../../models/game/solitaire.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      title: Text(game.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          valueLabelBuilder(context, value),
          const SizedBox(height: 8),
          Stack(
            children: [
              LinearProgressIndicator(
                minHeight: 8,
                borderRadius: BorderRadius.circular(24),
                value: value / maxRefValue,
              ),
              if (secondaryValue != null)
                LinearProgressIndicator(
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(24),
                  value: secondaryValue! / maxRefValue,
                  color: colorScheme.tertiaryContainer,
                  backgroundColor: Colors.transparent,
                ),
            ],
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
