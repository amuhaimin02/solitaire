import 'package:flutter/material.dart';

class InfoTile extends StatelessWidget {
  const InfoTile({super.key, required this.message});

  final Widget message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorScheme.onSurface.withOpacity(0.54);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: color, size: 20),
          const SizedBox(height: 16),
          DefaultTextStyle(
            style: textTheme.labelLarge!.copyWith(color: color),
            child: message,
          )
        ],
      ),
    );
  }
}
