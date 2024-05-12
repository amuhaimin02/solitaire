import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_layout.dart';

class CardMarker extends StatelessWidget {
  const CardMarker({super.key, required this.mark});

  final IconData mark;

  @override
  Widget build(BuildContext context) {
    final layout = context.watch<GameLayout>();

    return Container(
      width: layout.cardSize.width,
      height: layout.cardSize.height,
      padding: EdgeInsets.all(layout.cardPadding),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          mark,
          size: layout.cardSize.width * 0.5,
          color: Colors.black.withOpacity(0.07),
        ),
      ),
    );
  }
}
