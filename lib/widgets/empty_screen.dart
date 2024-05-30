import 'package:flutter/material.dart';

class EmptyScreen extends StatelessWidget {
  const EmptyScreen({super.key, this.icon, this.title, this.body});

  final Widget? icon;

  final Widget? title;

  final Widget? body;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              IconTheme(
                data: IconThemeData(size: 72, color: colorScheme.secondary),
                child: icon!,
              ),
            const SizedBox(height: 16),
            if (title != null)
              DefaultTextStyle(
                style: textTheme.titleLarge!
                    .copyWith(color: colorScheme.secondary),
                textAlign: TextAlign.center,
                child: title!,
              ),
            if (body != null) ...[
              const SizedBox(height: 16),
              DefaultTextStyle(
                style:
                    textTheme.bodyLarge!.copyWith(color: colorScheme.onSurface),
                textAlign: TextAlign.center,
                child: body!,
              ),
            ]
          ],
        ),
      ),
    );
  }
}
