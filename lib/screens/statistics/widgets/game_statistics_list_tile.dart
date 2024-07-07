import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../utils/types.dart';
import '../models/game_statistics_entry.dart';

class GameStatisticsListTile extends StatelessWidget {
  const GameStatisticsListTile({
    super.key,
    required this.index,
    required this.entry,
    this.showIndex = true,
    this.isVegasScoring = false,
  });

  final int index;
  final GameStatisticsEntry entry;
  final bool showIndex;
  final bool isVegasScoring;

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
      tileColor: index.isEven ? colorScheme.surfaceContainer : null,
      leading: showIndex
          ? SizedBox(
              width: 24,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${index + 1}',
                  style: textTheme.headlineSmall!
                      .copyWith(color: colorScheme.secondary),
                ),
              ),
            )
          : Icon(MdiIcons.circleSmall),
      horizontalTitleGap: 24,
      title: Wrap(
        spacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          buildIconTextPair(
              isVegasScoring ? MdiIcons.currencyUsd : MdiIcons.trophyVariant,
              entry.score.toString()),
          buildIconTextPair(MdiIcons.cards, entry.moves.toString()),
          buildIconTextPair(
              MdiIcons.clockOutline, entry.playTime.toSimpleHMSString()),
        ],
      ),
      subtitle: Text(entry.startedTime.toNaturalDateTimeString()),
      trailing: entry.isSolved
          ? Tooltip(
              message: 'This game is solved',
              child: Icon(MdiIcons.checkboxMarkedCircle),
            )
          : null,
    );
  }
}
