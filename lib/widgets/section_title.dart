import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.first = false});

  final String title;

  final bool first;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, first ? 0 : 32, 16, 8),
      child: Text(title,
          style: textTheme.titleMedium!.copyWith(color: colorScheme.primary)),
    );
  }
}
