import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../providers/settings.dart';
import '../../utils/host_platform.dart';
import '../../widgets/bottom_padded.dart';
import '../../widgets/info_tile.dart';
import '../../widgets/section_title.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Center(
        child: SizedBox(
          width: 600,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16) +
                BottomPadded.getPadding(context),
            children: [
              if (HostPlatform.isMobile) ...[
                const SectionTitle('System', first: true),
                SwitchListTile(
                  title: const Text('Show status bar'),
                  secondary: const Icon(Icons.web_asset),
                  value: ref.watch(settingsShowStatusBarProvider),
                  onChanged: (value) {
                    ref.read(settingsShowStatusBarProvider.notifier).toggle();
                  },
                ),
                SwitchListTile(
                  title: const Text('Show screen rotation button'),
                  subtitle: const Text(
                      'Allow manually changing orientation to portrait or landscape'),
                  secondary: const Icon(Icons.screen_rotation_alt),
                  value: ref.watch(settingsShowScreenRotateButtonProvider),
                  onChanged: (value) {
                    ref
                        .read(settingsShowScreenRotateButtonProvider.notifier)
                        .toggle();
                  },
                ),
              ],
              const SectionTitle('Feedback'),
              SwitchListTile(
                title: const Text('Sounds'),
                secondary: const Icon(Icons.volume_up),
                value: ref.watch(settingsEnableSoundsProvider),
                onChanged: (value) {
                  ref.read(settingsEnableSoundsProvider.notifier).toggle();
                },
              ),
              if (HostPlatform.isMobile)
                SwitchListTile(
                  title: const Text('Vibrations'),
                  secondary: const Icon(Icons.vibration),
                  value: ref.watch(settingsEnableVibrationProvider),
                  onChanged: (value) {
                    ref.read(settingsEnableVibrationProvider.notifier).toggle();
                  },
                ),
              const SectionTitle('In game'),
              SwitchListTile(
                title: const Text('Show score'),
                secondary: Icon(MdiIcons.numeric),
                value: ref.watch(settingsShowScoreProvider),
                onChanged: (value) {
                  ref.read(settingsShowScoreProvider.notifier).toggle();
                },
              ),
              SwitchListTile(
                title: const Text('Show moves'),
                secondary: Icon(MdiIcons.cards),
                value: ref.watch(settingsShowMoveCountProvider),
                onChanged: (value) {
                  ref.read(settingsShowMoveCountProvider.notifier).toggle();
                },
              ),
              SwitchListTile(
                title: const Text('Show play time'),
                secondary: Icon(MdiIcons.timerOutline),
                value: ref.watch(settingsShowPlayTimeProvider),
                onChanged: (value) {
                  ref.read(settingsShowPlayTimeProvider.notifier).toggle();
                },
              ),
              const InfoTile(
                message: Text('Scores, moves and time will still be recorded.'),
              ),
              const SectionTitle('Controls'),
              SwitchListTile(
                title: const Text('Drag & drop'),
                secondary: Icon(MdiIcons.gestureSwipe),
                subtitle: const Text(
                    'Drag and drop cards around to make a move. Will always be enabled'),
                value: true,
                onChanged: null,
              ),
              SwitchListTile(
                title: const Text('One-tap move'),
                secondary: Icon(MdiIcons.gestureTap),
                subtitle: const Text(
                    'Tap on a card to automatically move to its possible places'),
                value: ref.watch(settingsUseOneTapMoveProvider),
                onChanged: (value) {
                  ref.read(settingsUseOneTapMoveProvider.notifier).toggle();
                  if (value) {
                    ref.read(settingsUseTwoTapMoveProvider.notifier).set(false);
                  }
                },
              ),
              SwitchListTile(
                title: const Text('Two-tap move'),
                secondary: Icon(MdiIcons.handPeaceVariant),
                subtitle:
                    const Text('Tap on a card and a destination to move it'),
                value: ref.watch(settingsUseTwoTapMoveProvider),
                onChanged: (value) {
                  ref.read(settingsUseTwoTapMoveProvider.notifier).toggle();
                  if (value) {
                    ref.read(settingsUseOneTapMoveProvider.notifier).set(false);
                  }
                },
              ),
              const InfoTile(
                message: Text(
                    'Only either one-tap or two-tap move can be enabled at a time'),
              ),
              const SectionTitle('Assistance'),
              SwitchListTile(
                title: const Text('Auto pre-move'),
                secondary: Icon(MdiIcons.transferRight),
                subtitle: const Text(
                    'Cards will be moved to foundations whenever possible'),
                value: ref.watch(settingsUseAutoPremoveProvider),
                onChanged: (value) {
                  ref.read(settingsUseAutoPremoveProvider.notifier).toggle();
                },
              ),
              SwitchListTile(
                title: const Text('Show auto solve button'),
                secondary: Icon(MdiIcons.autoFix),
                subtitle:
                    const Text('Quickly finish the game if winning is near'),
                value: ref.watch(settingsShowAutoSolveButtonProvider),
                onChanged: (value) {
                  ref
                      .read(settingsShowAutoSolveButtonProvider.notifier)
                      .toggle();
                },
              ),
              SwitchListTile(
                title: const Text('Show hint button'),
                secondary: const Icon(Icons.lightbulb),
                subtitle: const Text(
                    'Highlight all cards with possible moves during play'),
                value: ref.watch(settingsShowHintButtonProvider),
                onChanged: (value) {
                  ref.read(settingsShowHintButtonProvider.notifier).toggle();
                },
              ),
              SwitchListTile(
                title: const Text('Show undo/redo button'),
                secondary: const Icon(Icons.undo),
                subtitle: const Text('Allow undos and redos during play'),
                value: ref.watch(settingsShowUndoRedoButtonProvider),
                onChanged: (value) {
                  ref
                      .read(settingsShowUndoRedoButtonProvider.notifier)
                      .toggle();
                },
              ),
              const InfoTile(
                message: Text('Some games might not support these controls.'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
