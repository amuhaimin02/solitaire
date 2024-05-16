import 'package:flutter/material.dart';

import '../animations.dart';

class TouchFocusable extends StatelessWidget {
  const TouchFocusable(
      {super.key,
      this.active = true,
      required this.child,
      this.opacityWhenUnfocus = 0.5});

  final bool active;

  final double opacityWhenUnfocus;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !active,
      child: AnimatedOpacity(
        duration: themeChangeAnimation.duration,
        curve: themeChangeAnimation.curve,
        opacity: active ? 1 : opacityWhenUnfocus,
        child: child,
      ),
    );
  }
}
