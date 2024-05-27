import 'package:flutter/services.dart';

enum ScreenOrientation { auto, landscape, portrait }

class SystemWindow {
  static void changeOrientation(ScreenOrientation orientation) {
    print('Changing orientation $orientation');
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

  static setStatusBarVisibility(bool visible) {
    print('Set status bar $visible');
    if (visible) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    }
  }
}
