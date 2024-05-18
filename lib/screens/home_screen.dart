import 'dart:math';

import 'package:flutter/material.dart';

import '../models/card.dart';
import '../models/pile.dart';
import '../models/rules/klondike.dart';
import '../models/rules/rules.dart';
import '../widgets/game_table.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final rules = Klondike();

    final cards = PlayCards.fromRules(rules);
    cards(const Draw()).addAll(rules.prepareDrawPile(Random()).allFaceDown);

    rules.setup(cards);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.pushNamed(context, '/game');
        },
        child: Padding(
          padding: const EdgeInsets.all(72),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: 400, maxHeight: 400),
                  child: Center(
                    child: GameTable(
                      interactive: false,
                      layout: rules.getLayout(
                        LayoutOptions(
                          orientation: Orientation.portrait,
                          mirror: false,
                        ),
                      ),
                      cards: cards,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Touch to continue',
                style: textTheme.bodyLarge!
                    .copyWith(color: colorScheme.onPrimaryContainer),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
