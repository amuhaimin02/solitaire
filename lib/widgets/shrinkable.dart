import 'package:flutter/material.dart';

import '../animations.dart';

class Shrinkable extends StatelessWidget {
  const Shrinkable({
    super.key,
    required this.child,
    this.show = true,
    this.alignment = Alignment.center,
  });

  final Widget child;

  final bool show;

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: standardAnimation.duration,
      curve: standardAnimation.curve,
      scale: show ? 1.0 : 0.0,
      alignment: alignment,
      child: show ? child : null,
    );
  }
}
