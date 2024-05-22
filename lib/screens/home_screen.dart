import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../animations.dart';
import '../models/game_selection_state.dart';
import '../models/game_state.dart';
import '../models/pile.dart';
import '../models/rules/klondike.dart';
import '../providers/settings.dart';
import '../widgets/game_table.dart';
import '../widgets/fast_page_view.dart';
import '../widgets/section_title.dart';
import '../widgets/solitaire_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _variantSelectionOpened = false;

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
                        ],
                      ),
                    ),
                    Container(
                      width: 400,
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: _GameVariantDropdown(
                                onTap: _toggleVariantDropdown,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 8,
                            child: Column(
                              children: [
                                if (_variantSelectionOpened)
                                  _GameVariantSelection(
                                    onTapDone: _toggleVariantDropdown,
                                  )
                                else ...[
                                  const Expanded(
                                    flex: 4,
                                    child: Center(
                                      child: _GameMenu(),
                                    ),
                                  ),
                                  const Spacer(),
                                ],
                              ],
                            ),
                          ),
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
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            const Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: _GameTitle(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _GameVariantDropdown(
                              onTap: _toggleVariantDropdown,
                            )
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: Column(
                        children: [
                          if (_variantSelectionOpened) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32),
                              child: _GameVariantSelection(
                                onTapDone: _toggleVariantDropdown,
                              ),
                            ),
                          ] else ...[
                            Expanded(
                              child:
                                  _GameTypeSelection(orientation: orientation),
                            ),
                            const _GameMenu(),
                            const SizedBox(height: 48),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
            }
          },
        ),
      ),
    );
  }

  void _toggleVariantDropdown() {
    setState(() {
      _variantSelectionOpened = !_variantSelectionOpened;
    });
  }
}

class _GameTitle extends StatelessWidget {
  const _GameTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final selection = context.watch<GameSelectionState>();

    return ShaderMask(
      shaderCallback: (rect) {
        return LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect);
      },
      child: Text(
        selection.rules.name,
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
    final selection = context.watch<GameSelectionState>();
    final rules = selection.rules;

    return FastPageView(
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

class _GameVariantDropdown extends StatelessWidget {
  const _GameVariantDropdown({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selection = context.watch<GameSelectionState>();
    final variant = selection.variant;

    if (variant == null) {
      return const SizedBox();
    }

    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        padding:
            const EdgeInsets.only(left: 16, right: 8), // Restore visual balance
      ),
      iconAlignment: IconAlignment.end,
      label: Text(variant.name),
      icon: const Icon(Icons.arrow_drop_down),
      onPressed: onTap,
    );
  }
}

class _GameVariantSelection extends StatelessWidget {
  const _GameVariantSelection({super.key, required this.onTapDone});

  final VoidCallback onTapDone;

  @override
  Widget build(BuildContext context) {
    final selection = context.watch<GameSelectionState>();
    final variant = selection.variant as KlondikeVariant;

    return Column(
      children: [
        const SectionTitle('Number of draws'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('1 draw'),
              selected: variant.numberOfDraws == 1,
              onSelected: (_) => _onVariantSelected(
                  context,
                  KlondikeVariant(
                      numberOfDraws: 1, scoringType: variant.scoringType)),
            ),
            ChoiceChip(
              label: const Text('3 draws'),
              selected: variant.numberOfDraws == 3,
              onSelected: (_) => _onVariantSelected(
                  context,
                  KlondikeVariant(
                      numberOfDraws: 3, scoringType: variant.scoringType)),
            ),
          ],
        ),
        const SectionTitle('Scoring type'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final scoringType in KlondikeScoring.values)
              ChoiceChip(
                label: Text(scoringType.fullName),
                selected: variant.scoringType == scoringType,
                onSelected: (_) => _onVariantSelected(
                    context,
                    KlondikeVariant(
                        numberOfDraws: variant.numberOfDraws,
                        scoringType: scoringType)),
              ),
          ],
        ),
        const SizedBox(height: 40),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 56),
          ),
          onPressed: onTapDone,
          child: const Text('Done'),
        ),
      ],
    );
  }

  void _onVariantSelected(BuildContext context, KlondikeVariant variant) {
    context.read<GameSelectionState>().setVariant(variant);
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
              context
                  .read<SettingsManager>()
                  .set(Settings.themeColor, themeColorPalette.sample(1).single);
            }

            final selection = context.read<GameSelectionState>();
            final gameState = context.read<GameState>();

            gameState.rules = selection.rules;
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
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
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
          spacing: 16,
          children: [
            IconButton(
              onPressed: () {},
              tooltip: "Help",
              icon: const Icon(Icons.help),
            ),
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/stats');
              },
              tooltip: "Statistics",
              icon: const Icon(Icons.leaderboard),
            ),
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/customize');
              },
              tooltip: "Customize",
              icon: const Icon(Icons.imagesearch_roller),
            ),
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
              tooltip: "Settings",
              icon: const Icon(Icons.settings),
            ),
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/about');
              },
              tooltip: "About",
              icon: const Icon(Icons.info),
            ),
          ],
        )
      ],
    );
  }
}
