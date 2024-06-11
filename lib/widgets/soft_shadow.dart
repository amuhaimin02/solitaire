import 'package:flutter/material.dart';

class SoftShadow extends BoxShadow {
  SoftShadow(double pixels, {Color? color})
      : super(
          color: (color ?? Colors.black.withOpacity(0.1)),
          offset: Offset(0, pixels),
          blurRadius: pixels * 2,
        );
}
