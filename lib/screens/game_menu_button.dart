import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../providers/settings.dart';
import '../services/system_window.dart';
import '../utils/widgets.dart';

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
    return IconButton(
      tooltip: 'Menu',
      onPressed: () => _onPressed(context),
      icon: const Icon(Icons.more_horiz),
    );
  }

  Future<void> _onPressed(BuildContext context) async {
    final buttonPosition = context.globalPaintBounds!;
    HapticFeedback.mediumImpact();

    final orientation = MediaQuery.of(context).orientation;

    final dialogAnchor = switch (orientation) {
      Orientation.portrait => buttonPosition.bottomLeft,
      Orientation.landscape => buttonPosition.topRight,
    };

    final allOptions = [
      _GameMenuOptions(
        icon: MdiIcons.cardsPlaying,
        label: 'Select game',
        onTap: (context) => Navigator.pushNamed(context, '/select'),
      ),
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
        icon: Icons.info,
        label: 'About',
        onTap: (context) => Navigator.pushNamed(context, '/about'),
      )
    ];

    final selectedOptions = await showGeneralDialog<_GameMenuOptions>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black26,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: <Widget>[
            Positioned.fill(
              left: dialogAnchor.dx,
              top: dialogAnchor.dy,
              child: Align(
                alignment: Alignment.topLeft,
                child: ScaleTransition(
                  scale: CurveTween(curve: Easing.emphasizedDecelerate)
                      .animate(animation),
                  alignment: Alignment.topLeft,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    width: 240,
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 24,
                      borderRadius: BorderRadius.circular(16),
                      child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        children: [
                          const _ScreenOrientationToggle(),
                          const Divider(),
                          for (final option in allOptions)
                            ListTile(
                              leading: Icon(option.icon),
                              title: Text(option.label),
                              onTap: () {
                                Navigator.pop(context, option);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        );
      },
    );

    if (selectedOptions != null && context.mounted) {
      selectedOptions.onTap(context);
    }
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
