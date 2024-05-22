import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../models/pile.dart';
import '../models/rules/klondike.dart';
import '../providers/settings.dart';
import '../widgets/game_table.dart';
import '../widgets/pager.dart';
import '../widgets/solitaire_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final orientation = constraints.maxWidth > 800
                ? Orientation.landscape
                : Orientation.portrait;

            switch (orientation) {
              case Orientation.landscape:
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Spacer(),
                          const _GameTitle(),
                          Expanded(
                            flex: 6,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child:
                                  _GameTypeSelection(orientation: orientation),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 48),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _GameVariantSelection(),
                          SizedBox(height: 32),
                          _GameMenu(),
                        ],
                      ),
                    ),
                  ],
                );
              case Orientation.portrait:
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          _GameTitle(),
                          SizedBox(height: 16),
                          _GameVariantSelection()
                        ],
                      ),
                    ),
                    Expanded(
                        flex: 6,
                        child: _GameTypeSelection(orientation: orientation)),
                    const _GameMenu(),
                    const Spacer(),
                  ],
                );
            }
          },
        ),
      ),
    );
  }
}

class _GameTitle extends StatelessWidget {
  const _GameTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return ShaderMask(
      shaderCallback: (rect) {
        return LinearGradient(
          colors: [colorScheme.primary, colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect);
      },
      child: Text(
        'Klondike',
        style: textTheme.displayMedium!.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _GameTypeSelection extends StatelessWidget {
  const _GameTypeSelection({super.key, required this.orientation});

  final Orientation orientation;

  @override
  Widget build(BuildContext context) {
    final rules = Klondike();

    return Pager(
      itemCount: 5,
      itemBuilder: (context, index) {
        final cards = PlayCards.fromRules(rules);
        cards(const Draw())
            .addAll(rules.prepareDrawPile(Random(index)).allFaceDown);
        rules.setup(cards);
        return GameTable(
          key: ValueKey(index),
          interactive: false,
          animateMovement: false,
          rules: rules,
          orientation: orientation,
          cards: cards,
        );
      },
    );
  }
}

class _GameVariantSelection extends StatelessWidget {
  const _GameVariantSelection({super.key});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        padding:
            const EdgeInsets.only(left: 16, right: 8), // Restore visual balance
      ),
      iconAlignment: IconAlignment.end,
      label: const Text('1 draw, standard scoring'),
      icon: const Icon(Icons.arrow_drop_down),
      onPressed: () {},
    );
  }
}

class _GameMenu extends StatelessWidget {
  const _GameMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.tonalIcon(
          onPressed: () {
            if (context
                .read<SettingsManager>()
                .get(Settings.randomizeThemeColor)) {
              _changeThemeRandomColor(context);
            }

            final gameState = context.read<GameState>();
            gameState.startNewGame();
            Navigator.pushNamed(context, '/game');
          },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 56),
          ),
          label: const Text('New game'),
          icon: Icon(MdiIcons.cardsPlaying),
        ),
        const SizedBox(height: 8),
        Visibility(
          visible: gameState.status == GameStatus.started,
          child: FilledButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/game');
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 56),
            ),
            label: const Text('Continue last game'),
            icon: Icon(MdiIcons.cardsPlaying),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 24,
          children: [
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/stats');
              },
              icon: const Icon(Icons.leaderboard),
            ),
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/theme');
              },
              icon: const Icon(Icons.imagesearch_roller),
            ),
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
              icon: const Icon(Icons.settings),
            ),
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/about');
              },
              icon: const Icon(Icons.info),
            ),
          ],
        )
      ],
    );
  }

  void _changeThemeRandomColor(BuildContext context) {
    context
        .read<SettingsManager>()
        .set(Settings.themeColor, themeColorPalette.sample(1).single);
  }
}
