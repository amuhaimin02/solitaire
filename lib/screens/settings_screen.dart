import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../providers/settings.dart';
import '../services/system_window.dart';
import '../widgets/fading_edge_list_view.dart';
import '../widgets/section_title.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        scrolledUnderElevation: 0,
      ),
      body: Center(
        child: SizedBox(
          width: 600,
          child: FadingEdgeListView(
            verticalPadding: 32,
            children: [
              const SectionTitle('System', first: true),
              SwitchListTile(
                title: const Text('Show status bar'),
                secondary: const Icon(Icons.web_asset),
                value: ref.watch(settingsShowStatusBarProvider),
                onChanged: (value) {
                  ref.read(settingsShowStatusBarProvider.notifier).toggle();
                },
              ),
              const SectionTitle('Appearance'),
              SwitchListTile(
                title: const Text('Highlight last moves'),
                secondary: const Icon(Icons.crop_portrait),
                subtitle: const Text(
                    'Recently moved cards will be indicated with a border'),
                value: ref.watch(settingsShowLastMoveProvider),
                onChanged: (value) {
                  ref.read(settingsShowLastMoveProvider.notifier).toggle();
                },
              ),
              SwitchListTile(
                title: const Text('Show score'),
                secondary: Icon(MdiIcons.counter),
                subtitle: const Text('Show score obtained during play'),
                value: ref.watch(settingsShowScoreProvider),
                onChanged: (value) {
                  ref.read(settingsShowScoreProvider.notifier).toggle();
                },
              ),
              SwitchListTile(
                title: const Text('Show moves'),
                secondary: Icon(MdiIcons.cards),
                subtitle: const Text('Show number of moves during play'),
                value: ref.watch(settingsShowMoveCountProvider),
                onChanged: (value) {
                  ref.read(settingsShowMoveCountProvider.notifier).toggle();
                },
              ),
              SwitchListTile(
                title: const Text('Show time'),
                secondary: Icon(MdiIcons.timerOutline),
                subtitle: const Text('Show play time during play'),
                value: ref.watch(settingsShowPlayTimeProvider),
                onChanged: (value) {
                  ref.read(settingsShowPlayTimeProvider.notifier).toggle();
                },
              ),
              const SectionTitle('Behavior'),
              SwitchListTile(
                title: const Text('One tap move'),
                secondary: Icon(MdiIcons.gestureTap),
                subtitle: const Text(
                    'Tapping on cards will automatically move to possible places'),
                value: ref.watch(settingsUseOneTapMoveProvider),
                onChanged: (value) {
                  ref.read(settingsUseOneTapMoveProvider.notifier).toggle();
                },
              ),
              SwitchListTile(
                title: const Text('Auto pre-move'),
                secondary: Icon(MdiIcons.transferRight),
                subtitle: const Text(
                    'Cards will be moved to winning position when possible after each move'),
                value: ref.watch(settingsUseAutoPremoveProvider),
                onChanged: (value) {
                  ref.read(settingsUseAutoPremoveProvider.notifier).toggle();
                },
              ),
              SwitchListTile(
                title: const Text('Show auto solve button'),
                secondary: Icon(MdiIcons.autoFix),
                subtitle: const Text(
                    'If solution is possible, auto solve button will automatically finish the game'),
                value: ref.watch(settingsShowAutoSolveButtonProvider),
                onChanged: (value) {
                  ref
                      .read(settingsShowAutoSolveButtonProvider.notifier)
                      .toggle();
                },
              ),
              const SectionTitle('Feedback'),
              SwitchListTile(
                title: const Text('Sounds'),
                secondary: const Icon(Icons.volume_up),
                value: ref.watch(settingsEnableSoundsProvider),
                onChanged: (value) {
                  ref.read(settingsEnableSoundsProvider.notifier).toggle();
                },
              ),
              SwitchListTile(
                title: const Text('Vibrations'),
                secondary: const Icon(Icons.vibration),
                value: ref.watch(settingsEnableVibrationProvider),
                onChanged: (value) {
                  ref.read(settingsEnableVibrationProvider.notifier).toggle();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
