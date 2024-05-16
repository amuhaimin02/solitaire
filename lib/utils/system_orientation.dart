import 'package:flutter/services.dart';

enum SystemOrientation { auto, landscape, portrait }

class SystemOrientationManager {
  static void change(SystemOrientation orientation) {
    print('Changing orientation to $orientation');
    switch (orientation) {
      case SystemOrientation.auto:
        SystemChrome.setPreferredOrientations([]);
      case SystemOrientation.landscape:
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight
        ]);
      case SystemOrientation.portrait:
        SystemChrome.setPreferredOrientations(
            [DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);
    }
  }
}
