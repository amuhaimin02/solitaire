import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/lists.dart';

enum SystemOrientation { auto, landscape, portrait }

class SystemOrientationManager with ChangeNotifier {
  SystemOrientation _orientation = SystemOrientation.auto;

  void set(SystemOrientation orientation) {
    _orientation = orientation;

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

    notifyListeners();
  }

  void toggle() {
    set(SystemOrientation.values.toggle(_orientation));
  }

  SystemOrientation get current => _orientation;
}
