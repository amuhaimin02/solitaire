import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../providers/game_logic.dart';
import '../../../widgets/overlay_button.dart';
import 'debug_pane.dart';

class _GameMenuOptions {
  final IconData icon;
  final String label;
  final Function(BuildContext context) onTap;

  _GameMenuOptions(
      {required this.icon, required this.label, required this.onTap});
}

class GameMenuButton extends StatelessWidget {
  const GameMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final allOptions = [
      _GameMenuOptions(
        icon: Icons.color_lens,
        label: 'Customize',
        onTap: (context) => context.go('/theme'),
      ),
      _GameMenuOptions(
        icon: Icons.settings,
        label: 'Settings',
        onTap: (context) => context.go('/settings'),
      ),
      _GameMenuOptions(
        icon: Icons.leaderboard,
        label: 'Statistics',
        onTap: (context) => context.go('/statistics'),
      ),
    ];

    return SizedBox.square(
      dimension: kToolbarHeight,
      child: OverlayButton.icon(
        tooltip: 'Menu',
        icon: const Icon(Icons.menu),
        overlayBuilder: (context) {
          void dismiss() {
            Navigator.pop(context);
          }

          return [
            const SizedBox(height: 4),
            const _CurrentGameDisplay(),
            ListTile(
              leading: Icon(MdiIcons.cardsPlaying),
              title: const Text('Change game'),
              onTap: () {
                dismiss();
                context.go('/select');
              },
            ),
            const Divider(),
            for (final option in allOptions)
              ListTile(
                leading: Icon(option.icon),
                title: Text(option.label),
                onTap: () {
                  dismiss();
                  option.onTap(context);
                },
              ),
            // const Divider(),
            // const Padding(
            //   padding: EdgeInsets.all(8.0),
            //   child: DebugPane(),
            // ),
          ];
        },
      ),
    );
  }
}

class _CurrentGameDisplay extends ConsumerWidget {
  const _CurrentGameDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final currentGame = ref.watch(currentGameProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Now playing',
                  style: textTheme.labelLarge!
                      .copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  currentGame.kind.name,
                  style:
                      textTheme.bodyLarge!.copyWith(color: colorScheme.primary),
                ),
              ],
            ),
          ),
          // const SizedBox(width: 8),
          // Tooltip(
          //   message:
          //       'Seed: ${currentGame.seed}\nStarted on: ${currentGame.startedTime}',
          //   preferBelow: true,
          //   triggerMode: TooltipTriggerMode.tap,
          //   enableTapToDismiss: false,
          //   child: Icon(
          //     Icons.info_outline,
          //     size: 20,
          //     color: colorScheme.onPrimaryContainer,
          //   ),
          // )
        ],
      ),
    );
  }
}
