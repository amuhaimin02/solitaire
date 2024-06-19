import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/host_platform.dart';

class SystemWindow {
  const SystemWindow();

  Future<void> toggleOrientation(Orientation targetOrientation) async {
    if (HostPlatform.isMobile) {
      switch (targetOrientation) {
        case Orientation.landscape:
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight
          ]);
        case Orientation.portrait:
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitDown,
            DeviceOrientation.portraitUp,
          ]);
      }
    } else {
      throw ArgumentError(
          'Screen rotation is only supported on mobile platforms');
    }
  }

  void setStatusBarTheme(Brightness brightness) {
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

  void setStatusBarVisibility(bool visible) {
    SystemChrome.setEnabledSystemUIMode(
      visible ? SystemUiMode.edgeToEdge : SystemUiMode.immersiveSticky,
      // overlays: visible ? SystemUiOverlay.values : [],
    );
  }
}
