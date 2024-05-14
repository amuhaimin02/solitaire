import 'package:flutter/material.dart';

import '../animations.dart';

class Shrinkable extends StatelessWidget {
  const Shrinkable({super.key, required this.child, this.show = true});

  final Widget child;

  final bool show;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: standardAnimation.duration,
      curve: standardAnimation.curve,
      scale: show ? 1.0 : 0.0,
      child: child,
    );
  }
}
