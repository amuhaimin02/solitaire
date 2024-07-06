import 'package:flutter/material.dart';

class LeveledProgressBar extends StatelessWidget {
  const LeveledProgressBar({
    super.key,
    required this.value,
    this.secondaryValue,
  });

  final double value;
  final double? secondaryValue;

  static const trackHeight = 4.0;
  static const smallBarHeight = 8.0;
  static const largeBarHeight = 12.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget buildBar(double height, Color color) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(9999),
        ),
      );
    }

    return SizedBox(
      height: largeBarHeight,
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          buildBar(trackHeight, colorScheme.onSurface.withOpacity(0.38)),
          if (value > 0)
            if (secondaryValue != null) ...[
              FractionallySizedBox(
                widthFactor: value,
                child: buildBar(smallBarHeight, colorScheme.outline),
              ),
              FractionallySizedBox(
                widthFactor: secondaryValue,
                child: buildBar(largeBarHeight, colorScheme.primary),
              ),
            ] else
              FractionallySizedBox(
                widthFactor: value,
                child: buildBar(largeBarHeight, colorScheme.primary),
              ),
        ],
      ),
    );
  }
}
