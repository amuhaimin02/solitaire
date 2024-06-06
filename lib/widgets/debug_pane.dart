import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../providers/game_logic.dart';
import '../providers/game_selection.dart';
import '../providers/game_storage.dart';

class DebugPane extends ConsumerWidget {
  const DebugPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        IconButton(
          tooltip: 'Custom layout',
          onPressed: () {
            ref.read(gameDebugProvider.notifier).debugTestCustomLayout();
          },
          icon: Icon(MdiIcons.cardsPlaying),
        ),
        IconButton(
          tooltip: 'Delete all saves',
          onPressed: () {
            for (final game in ref.read(allSolitaireGamesProvider)) {
              ref.read(gameStorageProvider.notifier).deleteQuickSave(game);
            }
          },
          icon: Icon(MdiIcons.delete),
        ),
      ],
    );
  }
}
