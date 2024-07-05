import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../utils/types.dart';
import '../models/game_statistics_entry.dart';

class GameStatisticsListTile extends StatelessWidget {
  const GameStatisticsListTile(
      {super.key, required this.index, required this.entry});

  final int index;
  final GameStatisticsEntry entry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    Widget buildIconTextPair(IconData icon, String text) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(text),
        ],
      );
    }

    return ListTile(
      tileColor: entry.isSolved
          ? colorScheme.tertiaryContainer.withOpacity(0.38)
          : null,
      leading: SizedBox(
        width: textTheme.headlineMedium!.fontSize! * 1.2,
        child: Text(
          '${index + 1}',
          style:
              textTheme.headlineMedium!.copyWith(color: colorScheme.secondary),
          textAlign: TextAlign.end,
        ),
      ),
      horizontalTitleGap: 24,
      title: Wrap(
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          buildIconTextPair(MdiIcons.trophyVariant, entry.score.toString()),
          buildIconTextPair(MdiIcons.cards, entry.moves.toString()),
          buildIconTextPair(
              MdiIcons.clockOutline, entry.playTime.toNaturalHMSString()),
        ],
      ),
      subtitle: Text(entry.startedTime.toNaturalDateTimeString()),
      trailing:
          entry.isSolved ? Text('Solved', style: textTheme.labelLarge) : null,
    );
  }
}
