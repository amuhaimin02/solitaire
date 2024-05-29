import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../providers/game_logic.dart';
import '../providers/settings.dart';
import '../services/system_window.dart';
import '../widgets/popup_button.dart';

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
        onTap: (context) => Navigator.pushNamed(context, '/theme'),
      ),
      _GameMenuOptions(
        icon: Icons.settings,
        label: 'Settings',
        onTap: (context) => Navigator.pushNamed(context, '/settings'),
      ),
      _GameMenuOptions(
        icon: Icons.help,
        label: 'Help',
        onTap: (context) => Navigator.pushNamed(context, '/help'),
      ),
      _GameMenuOptions(
        icon: Icons.info,
        label: 'About',
        onTap: (context) => Navigator.pushNamed(context, '/about'),
      )
    ];

    return PopupButton(
      tooltip: 'Menu',
      icon: const Icon(Icons.menu),
      builder: (context, dismiss) {
        return [
          const _ScreenOrientationToggle(),
          const Divider(),
          const _CurrentGameDisplay(),
          ListTile(
            leading: Icon(MdiIcons.cardsPlaying),
            title: const Text('Change game'),
            onTap: () {
              dismiss();
              Navigator.pushNamed(context, '/select');
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
        ];
      },
    );
  }
}

class _ScreenOrientationToggle extends ConsumerWidget {
  const _ScreenOrientationToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentOrientation = ref.watch(settingsScreenOrientationProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        children: [
          IconButton.filled(
            tooltip: 'Auto rotate (follow system settings)',
            isSelected: currentOrientation == ScreenOrientation.auto,
            icon: const Icon(Icons.screen_rotation),
            onPressed: () => _change(context, ref, ScreenOrientation.auto),
          ),
          IconButton.filled(
            tooltip: 'Portrait',
            isSelected: currentOrientation == ScreenOrientation.portrait,
            icon: const Icon(Icons.stay_current_portrait),
            onPressed: () => _change(context, ref, ScreenOrientation.portrait),
          ),
          IconButton.filled(
            tooltip: 'Landscape',
            isSelected: currentOrientation == ScreenOrientation.landscape,
            icon: const Icon(Icons.stay_current_landscape),
            onPressed: () => _change(context, ref, ScreenOrientation.landscape),
          ),
        ],
      ),
    );
  }

  void _change(
      BuildContext context, WidgetRef ref, ScreenOrientation newOrientation) {
    ref.read(settingsScreenOrientationProvider.notifier).set(newOrientation);
    Navigator.pop(context);
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
            currentGame.rules.name,
            style: textTheme.bodyLarge!.copyWith(color: colorScheme.secondary),
          ),
        ],
      ),
    );
  }
}
