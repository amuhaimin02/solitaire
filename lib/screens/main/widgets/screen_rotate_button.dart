import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/settings.dart';
import '../../../services/all.dart';
import '../../../services/system_window.dart';
import '../../../utils/host_platform.dart';

class ScreenRotateButton extends ConsumerWidget {
  const ScreenRotateButton({super.key});

  static const size =
      kToolbarHeight; // match Material's AppBar leading icon size

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (HostPlatform.isMobile &&
        ref.watch(settingsShowScreenRotateButtonProvider)) {
      return SizedBox.square(
        dimension: size,
        child: IconButton(
          tooltip: 'Change screen rotation',
          onPressed: () {
            final currentOrientation = MediaQuery.of(context).orientation;

            final targetOrientation = switch (currentOrientation) {
              Orientation.portrait => Orientation.landscape,
              Orientation.landscape => Orientation.portrait,
            };
            services<SystemWindow>().toggleOrientation(targetOrientation);
          },
          icon: const Icon(Icons.screen_rotation_alt),
        ),
      );
    }
    return const SizedBox();
  }
}
