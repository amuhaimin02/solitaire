import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pile.dart';
import '../providers/settings.dart';
import '../utils/system_orientation.dart';
import '../widgets/fading_edge_list_view.dart';
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
              ListTile(
                title: const Text('Screen orientation'),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SegmentedButton<ScreenOrientation>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: ScreenOrientation.auto,
                        label: Text('Auto'),
                        icon: Icon(Icons.screen_rotation),
                      ),
                      ButtonSegment(
                        value: ScreenOrientation.portrait,
                        label: Text('Portrait'),
                        icon: Icon(Icons.stay_current_portrait),
                      ),
                      ButtonSegment(
                        value: ScreenOrientation.landscape,
                        label: Text('Landscape'),
                        icon: Icon(Icons.stay_current_landscape),
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
                title: const Text('Auto move'),
                subtitle: const Text(
                    'Cards will be moved to foundations whenever possible'),
                value:
                    settings.get(Settings.autoMoveLevel) != AutoMoveLevel.off,
                onChanged: (value) {
                  settings.set(Settings.autoMoveLevel,
                      value ? AutoMoveLevel.full : AutoMoveLevel.off);
                },
              ),
              SwitchListTile(
                title: const Text('Highlight last moves'),
                subtitle: const Text(
                    'Recently moved cards will be indicated with a border'),
                value: settings.get(Settings.showMoveHighlight),
                onChanged: (value) {
                  settings.toggle(Settings.showMoveHighlight);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
