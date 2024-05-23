import 'package:flutter/material.dart';

import '../animations.dart';

class AnimatedVisibility extends StatelessWidget {
  const AnimatedVisibility(
      {super.key, required this.visible, required this.child});

  final bool visible;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        duration: standardAnimation.duration,
        opacity: visible ? 1 : 0,
        child: child,
      ),
    );
  }
}
