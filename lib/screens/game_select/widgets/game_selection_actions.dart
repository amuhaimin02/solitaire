import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../providers/game_logic.dart';
import '../../../providers/game_storage.dart';
import '../../../widgets/overlay_button.dart';
import 'import_failed_dialog.dart';

class GameSelectionActions extends ConsumerWidget {
  const GameSelectionActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OverlayButton.icon(
      tooltip: 'More actions',
      icon: const Icon(Icons.more_vert),
      overlayBuilder: (popupContext) {
        void dismiss() {
          Navigator.pop(popupContext);
        }

        return [
          ListTile(
            leading: Icon(MdiIcons.trayArrowDown),
            title: const Text('Import game'),
            onTap: () async {
              dismiss();

              try {
                final gameData = await ref
                    .read(gameStorageProvider.notifier)
                    .importQuickSave();
                if (gameData != null) {
                  ref.read(gameControllerProvider.notifier).restore(gameData);
                }
                // Go back to game screen once imported
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (error) {
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => ImportFailedDialog(error: error),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: Icon(MdiIcons.trayArrowUp),
            title: const Text('Export game'),
            onTap: () async {
              dismiss();
              final gameData =
                  ref.read(gameControllerProvider.notifier).suspend();
              ref.read(gameStorageProvider.notifier).exportQuickSave(gameData);
            },
          ),
        ];
      },
    );
  }
}
