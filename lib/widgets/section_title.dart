import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.first = false});

  final String title;

  final bool first;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      title: Text(title),
      titleTextStyle:
          textTheme.titleMedium!.copyWith(color: colorScheme.primary),
    );
  }
}
