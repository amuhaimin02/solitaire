import 'package:flutter/material.dart';

class SoftShadow extends BoxShadow {
  SoftShadow(double pixels)
      : super(
          color: Colors.black.withOpacity(0.1),
          offset: Offset(0, pixels * 2),
          blurRadius: pixels * 6,
        );
}
