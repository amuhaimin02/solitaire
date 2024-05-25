import 'package:flutter/material.dart';

class ColorButton extends StatelessWidget {
  const ColorButton({
    super.key,
    required this.size,
    required this.color,
    this.isSelected = false,
    required this.onTap,
  });

  final double size;
  final Color color;

  final bool isSelected;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: isSelected
                ? Border.all(color: colorScheme.onSurface, width: 6)
                : null,
          ),
        ),
      ),
    );
  }
}
