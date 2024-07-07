import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

class TiledSelection<T> extends StatefulWidget {
  const TiledSelection({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelectionChanged,
  });

  final List<TiledSelectionItem<T>> items;

  final T selected;
  final void Function(T value) onSelectionChanged;

  @override
  State<TiledSelection<T>> createState() => _TiledSelectionState<T>();
}

class _TiledSelectionState<T> extends State<TiledSelection<T>> {
  late T _selected = widget.selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 160,
      child: ListView(
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(vertical: 8),
        scrollDirection: Axis.horizontal,
        children: widget.items.map((item) {
          final highlight = item.value == _selected;
          return InkWell(
            onTap: () {
              if (item != _selected) {
                setState(() {
                  _selected = item.value;
                });
                widget.onSelectionChanged(_selected);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: highlight
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.outline,
                ),
                color: highlight ? colorScheme.secondaryContainer : null,
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Column(
                children: [
                  SizedBox(width: 80, height: 80, child: item.child),
                  Expanded(
                    child: Center(
                      child: DefaultTextStyle(
                        style: textTheme.labelLarge!.copyWith(
                            color: highlight
                                ? colorScheme.onSecondaryContainer
                                : colorScheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                        child: item.label,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class TiledSelectionItem<T> {
  const TiledSelectionItem({
    required this.value,
    required this.label,
    required this.child,
  });

  final T value;
  final Widget label;
  final Widget child;
}
