// TODO: Temporary workaround to fix dialog theme when using Google Fonts
import 'package:flutter/material.dart';

class DialogThemeFix extends StatelessWidget {
  const DialogThemeFix({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Theme(
      data: Theme.of(context).copyWith(
        dialogTheme: DialogTheme(
          titleTextStyle: textTheme.headlineSmall!
              .copyWith(color: colorScheme.onPrimaryContainer),
          contentTextStyle: textTheme.bodyMedium!
              .copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ),
      child: child,
    );
  }
}
