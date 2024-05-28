import 'package:flutter/material.dart';

extension WidgetListExtension on List<Widget> {
  List<Widget> reverseIf(bool Function() condition) {
    if (condition()) {
      return reversed.toList();
    } else {
      return this;
    }
  }

  List<Widget> separatedBy(Widget separator) {
    if (length <= 1) {
      return this;
    }
    return [
      for (final (index, child) in indexed) ...[
        child,
        if (index < length - 1) separator
      ]
    ];
  }
}

extension GlobalPaintBounds on BuildContext {
  Rect? get globalPaintBounds {
    final renderObject = findRenderObject();
    final translation = renderObject?.getTransformTo(null).getTranslation();
    if (translation != null && renderObject?.paintBounds != null) {
      final offset = Offset(translation.x, translation.y);
      return renderObject!.paintBounds.shift(offset);
    } else {
      return null;
    }
  }
}