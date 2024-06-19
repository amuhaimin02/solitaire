import 'package:flutter/material.dart';

class MiniToast extends StatelessWidget {
  const MiniToast({
    super.key,
    this.backgroundColor,
    this.foregroundColor,
    required this.child,
  });

  final Color? backgroundColor;
  final Color? foregroundColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Material(
          color: backgroundColor ?? colorScheme.inverseSurface,
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: DefaultTextStyle(
              style: textTheme.titleSmall!.copyWith(
                  color: foregroundColor ?? colorScheme.onInverseSurface),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
