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

  static final _allOptions = [
    _GameMenuOptions(
      icon: MdiIcons.cardsPlaying,
      label: 'Select game',
      onTap: (context) {},
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
    final dialogAnchor = buttonPosition.center;

    HapticFeedback.mediumImpact();

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
                    margin: const EdgeInsets.all(24),
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
                          for (final option in _allOptions)
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
            onPressed: () {
              ref
                  .read(settingsScreenOrientationProvider.notifier)
                  .set(ScreenOrientation.auto);
            },
          ),
          IconButton.filled(
            tooltip: 'Portrait',
            isSelected: currentOrientation == ScreenOrientation.portrait,
            icon: const Icon(Icons.stay_current_portrait),
            onPressed: () {
              ref
                  .read(settingsScreenOrientationProvider.notifier)
                  .set(ScreenOrientation.portrait);
            },
          ),
          IconButton.filled(
            tooltip: 'Landscape',
            isSelected: currentOrientation == ScreenOrientation.landscape,
            icon: const Icon(Icons.stay_current_landscape),
            onPressed: () {
              ref
                  .read(settingsScreenOrientationProvider.notifier)
                  .set(ScreenOrientation.landscape);
            },
          ),
        ],
      ),
    );
  }
}
