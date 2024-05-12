import 'package:flutter/material.dart';

extension WidgetListExtension on List<Widget> {
  List<Widget> reverseIf(bool Function() condition) {
    if (condition()) {
      return reversed.toList();
    } else {
      return this;
    }
  }
}
