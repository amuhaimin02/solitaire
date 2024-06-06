import 'package:flutter/material.dart';
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

  static setStatusBarTheme(Brightness brightness) {
    print('Set status color $brightness');
    // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    //   statusBarBrightness: brightness,
    //   statusBarIconBrightness: brightness,
    //   systemNavigationBarColor: color,
    //   statusBarColor: color,
    // ));
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarIconBrightness: brightness,
      systemNavigationBarColor: Colors.black12,
      statusBarBrightness: brightness,
      statusBarIconBrightness: brightness,
      statusBarColor: Colors.black12,
      systemNavigationBarContrastEnforced: true,
      systemStatusBarContrastEnforced: true,
    ));
  }

  static setStatusBarVisibility(bool visible) {
    print('Set status bar $visible');

    SystemChrome.setEnabledSystemUIMode(
      visible ? SystemUiMode.edgeToEdge : SystemUiMode.immersiveSticky,
      // overlays: visible ? SystemUiOverlay.values : [],
    );
  }
}
