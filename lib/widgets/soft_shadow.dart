import 'package:flutter/material.dart';

class SoftShadow extends BoxShadow {
  SoftShadow(double pixels, {Color? color})
      : super(
          color: (color ?? Colors.black.withOpacity(0.18)),
          offset: Offset.zero,
          blurRadius: pixels * 3,
        );
}
