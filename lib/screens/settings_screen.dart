import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../models/pile.dart';
import '../providers/settings.dart';
import '../utils/system_orientation.dart';
import '../widgets/fading_edge_list_view.dart';
import '../widgets/section_title.dart';
import '../widgets/solitaire_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsManager>();
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
                    selected: {settings.get(Settings.screenOrientation)},
                    onSelectionChanged: (value) {
                      settings.set(Settings.screenOrientation, value.single);
                    },
                  ),
                ),
              ),
              SwitchListTile(
                title: const Text('Highlight last moves'),
                secondary: const Icon(Icons.crop_portrait),
                subtitle: const Text(
                    'Recently moved cards will be indicated with a border'),
                value: settings.get(Settings.showMoveHighlight),
                onChanged: (value) {
                  settings.toggle(Settings.showMoveHighlight);
                },
              ),
              SwitchListTile(
                title: const Text('Show score'),
                secondary: Icon(MdiIcons.counter),
                subtitle: const Text('Show score obtained during play'),
                value: settings.get(Settings.showScoreDuringPlay),
                onChanged: (value) {
                  settings.toggle(Settings.showScoreDuringPlay);
                },
              ),
              SwitchListTile(
                title: const Text('Show moves'),
                secondary: Icon(MdiIcons.cards),
                subtitle: const Text('Show number of moves during play'),
                value: settings.get(Settings.showMovesDuringPlay),
                onChanged: (value) {
                  settings.toggle(Settings.showMovesDuringPlay);
                },
              ),
              SwitchListTile(
                title: const Text('Show time'),
                secondary: Icon(MdiIcons.timerOutline),
                subtitle: const Text('Show play time during play'),
                value: settings.get(Settings.showTimeDuringPlay),
                onChanged: (value) {
                  settings.toggle(Settings.showTimeDuringPlay);
                },
              ),
              const SectionTitle('Behavior'),
              SwitchListTile(
                title: const Text('One tap move'),
                secondary: Icon(MdiIcons.gestureTap),
                subtitle: const Text(
                    'Tapping on cards will automatically move to possible places'),
                value: settings.get(Settings.oneTapMove),
                onChanged: (value) {
                  settings.toggle(Settings.oneTapMove);
                },
              ),
              SwitchListTile(
                title: const Text('Auto pre-move'),
                secondary: Icon(MdiIcons.transferRight),
                subtitle: const Text(
                    'Cards will be moved to winning position when possible after each move'),
                value: settings.get(Settings.autoPremove),
                onChanged: (value) {
                  settings.toggle(Settings.autoPremove);
                },
              ),
              SwitchListTile(
                title: const Text('Show auto solve button'),
                secondary: Icon(MdiIcons.autoFix),
                subtitle: const Text(
                    'If solution is possible, auto solve button will automatically finish the game'),
                value: settings.get(Settings.showAutoSolveButton),
                onChanged: (value) {
                  settings.toggle(Settings.showAutoSolveButton);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
