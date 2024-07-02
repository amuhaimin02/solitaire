import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/game/solitaire.dart';

class GameStatisticsListTile<T extends num> extends ConsumerWidget {
  const GameStatisticsListTile({
    super.key,
    required this.game,
    required this.valueLabelBuilder,
    required this.value,
    required this.secondaryValue,
    required this.maxRefValue,
  });

  final SolitaireGame game;
  final Widget Function(BuildContext, T) valueLabelBuilder;
  final T value;
  final T? secondaryValue;
  final T maxRefValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(game.name)),
          valueLabelBuilder(context, value),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Stack(
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
                color: colorScheme.onSurface,
                backgroundColor: Colors.transparent,
              ),
          ],
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }
}
