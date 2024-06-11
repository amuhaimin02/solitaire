import 'package:flutter/material.dart';

import '../../../models/game_theme.dart';

class ColorSelectionTile extends StatelessWidget {
  const ColorSelectionTile({
    super.key,
    required this.value,
    required this.options,
    required this.onTap,
  });

  final Color? value;

  final List<Color> options;

  final Function(Color) onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Wrap(
        alignment: WrapAlignment.start,
        children: [
          for (final color in themeColorPalette)
            IconButton(
              onPressed: () => onTap(color),
              isSelected: color.value == value?.value,
              iconSize: 32,
              icon: const Icon(Icons.circle_outlined),
              selectedIcon: const Icon(Icons.circle),
              color: color,
            ),
        ],
      ),
    );
  }
}
