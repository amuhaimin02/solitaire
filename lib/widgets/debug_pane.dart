import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../providers/game_logic.dart';

class DebugPane extends ConsumerWidget {
  const DebugPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Text(ref.watch(gameControllerProvider).name,
          //     style: const TextStyle(color: Colors.white)),
          IconButton(
            onPressed: () {
              ref.read(gameDebugProvider.notifier).debugTestCustomLayout();
            },
            icon: Icon(MdiIcons.cardsPlaying),
          ),
        ],
      ),
    );
  }
}
