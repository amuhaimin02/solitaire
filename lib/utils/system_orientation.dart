import 'package:flutter/services.dart';

enum ScreenOrientation { auto, landscape, portrait }

class ScreenOrientationManager {
  static void change(ScreenOrientation orientation) {
    switch (orientation) {
      case ScreenOrientation.auto:
        SystemChrome.setPreferredOrientations([]);
      case ScreenOrientation.landscape:
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight
        ]);
      case ScreenOrientation.portrait:
        SystemChrome.setPreferredOrientations(
            [DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);
    }
  }
}
