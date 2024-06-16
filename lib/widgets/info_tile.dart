import 'package:flutter/material.dart';

class InfoTile extends StatelessWidget {
  const InfoTile({super.key, required this.message});

  final Widget message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorScheme.tertiary;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        leading: Icon(Icons.info_outline, color: color, size: 20),
        title: message,
        titleTextStyle: textTheme.labelLarge!.copyWith(color: color),
      ),
    );
  }
}
