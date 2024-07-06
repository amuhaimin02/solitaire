import 'package:flutter/material.dart';

class InfoTile extends StatelessWidget {
  const InfoTile({super.key, required this.message});

  final Widget message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorScheme.secondary;

    return ListTile(
      leading: const SizedBox(),
      title: message,
      titleTextStyle: textTheme.labelLarge!.copyWith(color: color),
    );
  }
}
