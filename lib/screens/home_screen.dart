import 'dart:math';

import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../models/card.dart';
import '../models/pile.dart';
import '../models/rules/klondike.dart';
import '../models/rules/rules.dart';
import '../widgets/game_table.dart';
import '../widgets/pager.dart';
import '../widgets/solitaire_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: OrientationBuilder(
            builder: (context, orientation) {
              switch (orientation) {
                case Orientation.landscape:
                  return const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(child: _GameSelection()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 64),
                        child: _GameOptions(),
                      ),
                    ],
                  );
                case Orientation.portrait:
                  return const Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(child: _GameSelection()),
                      _GameOptions(),
                    ],
                  );
              }
            },
          ),
        ),
      ),
    );
  }
}

class _GameSelection extends StatelessWidget {
  const _GameSelection({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final rules = Klondike();
    final cards = PlayCards.fromRules(rules);
    cards(const Draw()).addAll(rules.prepareDrawPile(Random()).allFaceDown);

    rules.setup(cards);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Klondike',
            style: textTheme.displayMedium!
                .copyWith(color: SolitaireTheme.of(context).foregroundColor)),
        const SizedBox(height: 32),
        Flexible(
          child: Pager(
            builder: (context) {
              return ConstrainedBox(
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
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GameOptions extends StatelessWidget {
  const _GameOptions({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.extended(
          backgroundColor: colorScheme.onPrimaryContainer,
          foregroundColor: colorScheme.primaryContainer,
          onPressed: () {
            Navigator.pushNamed(context, '/game');
          },
          label: const Text('Play game'),
          icon: Icon(MdiIcons.cardsPlaying),
        ),
      ],
    );
  }
}
