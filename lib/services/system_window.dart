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

  static setStatusBarTheme(Brightness brightness, Color color) {
    print('Set status color $brightness $color');
    // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    //   statusBarBrightness: brightness,
    //   statusBarIconBrightness: brightness,
    //   systemNavigationBarColor: color,
    //   statusBarColor: color,
    // ));
  }

  static setStatusBarVisibility(bool visible) {
    print('Set status bar $visible');

    SystemChrome.setEnabledSystemUIMode(
      visible ? SystemUiMode.manual : SystemUiMode.immersiveSticky,
      overlays: visible ? SystemUiOverlay.values : [],
    );
  }
}
