import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../providers/settings.dart';
import '../utils/system_orientation.dart';
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
              const SectionTitle('Appearance', first: true),
              ListTile(
                title: const Text('Screen orientation'),
                leading: const Icon(Icons.screen_rotation_alt),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SegmentedButton<ScreenOrientation>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: ScreenOrientation.auto,
                        label: Text('Auto'),
                        // icon: Icon(Icons.screen_rotation),
                      ),
                      ButtonSegment(
                        value: ScreenOrientation.portrait,
                        label: Text('Portrait'),
                        // icon: Icon(Icons.stay_current_portrait),
                      ),
                      ButtonSegment(
                        value: ScreenOrientation.landscape,
                        label: Text('Landscape'),
                        // icon: Icon(Icons.stay_current_landscape),
                      ),
                    ],
                    selected: {ref.watch(appScreenOrientationProvider)},
                    onSelectionChanged: (value) {
                      ref
                          .read(appScreenOrientationProvider.notifier)
                          .set(value.single);
                    },
                  ),
                ),
              ),
              SwitchListTile(
                title: const Text('Highlight last moves'),
                secondary: const Icon(Icons.crop_portrait),
                subtitle: const Text(
                    'Recently moved cards will be indicated with a border'),
                value: ref.watch(showLastMovesProvider),
                onChanged: (value) {
                  ref.read(showLastMovesProvider.notifier).toggle();
                },
              ),
              SwitchListTile(
                title: const Text('Show score'),
                secondary: Icon(MdiIcons.counter),
                subtitle: const Text('Show score obtained during play'),
                value: ref.watch(showScoreProvider),
                onChanged: (value) {
                  ref.read(showScoreProvider.notifier).toggle();
                },
              ),
              SwitchListTile(
                title: const Text('Show moves'),
                secondary: Icon(MdiIcons.cards),
                subtitle: const Text('Show number of moves during play'),
                value: ref.watch(showMovesProvider),
                onChanged: (value) {
                  ref.read(showMovesProvider.notifier).toggle();
                },
              ),
              SwitchListTile(
                title: const Text('Show time'),
                secondary: Icon(MdiIcons.timerOutline),
                subtitle: const Text('Show play time during play'),
                value: ref.watch(showTimeProvider),
                onChanged: (value) {
                  ref.read(showTimeProvider.notifier).toggle();
                },
              ),
              const SectionTitle('Behavior'),
              SwitchListTile(
                title: const Text('One tap move'),
                secondary: Icon(MdiIcons.gestureTap),
                subtitle: const Text(
                    'Tapping on cards will automatically move to possible places'),
                value: ref.watch(oneTapMoveProvider),
                onChanged: (value) {
                  ref.read(oneTapMoveProvider.notifier).toggle();
                },
              ),
              SwitchListTile(
                title: const Text('Auto pre-move'),
                secondary: Icon(MdiIcons.transferRight),
                subtitle: const Text(
                    'Cards will be moved to winning position when possible after each move'),
                value: ref.watch(autoPremoveProvider),
                onChanged: (value) {
                  ref.read(autoPremoveProvider.notifier).toggle();
                },
              ),
              SwitchListTile(
                title: const Text('Show auto solve button'),
                secondary: Icon(MdiIcons.autoFix),
                subtitle: const Text(
                    'If solution is possible, auto solve button will automatically finish the game'),
                value: ref.watch(showAutoSolveButtonProvider),
                onChanged: (value) {
                  ref.read(showAutoSolveButtonProvider.notifier).toggle();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
