import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../animations.dart';
import '../models/pile.dart';
import '../models/rules/rules.dart';
import '../models/states/game.dart';
import '../providers/game_logic.dart';
import '../widgets/animated_visibility.dart';
import '../widgets/control_pane.dart';
import '../widgets/game_table.dart';
import '../widgets/ripple_background.dart';
import '../widgets/shrinkable.dart';
import '../widgets/solitaire_theme.dart';
import '../widgets/status_pane.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  @override
  void initState() {
    // TODO: Do not initiate here
    super.initState();
    Future.microtask(() {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is SolitaireGame) {
        ref.read(gameControllerProvider.notifier).startNew(args);
      } else {
        throw ArgumentError('Please pass a SolitaireRules as the argument');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = SolitaireTheme.of(context);
    final viewPadding = MediaQuery.of(context).viewPadding;

    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
      ),
      extendBodyBehindAppBar: true,
      body: RippleBackground(
        decoration: BoxDecoration(color: theme.tableBackgroundColor),
        child: OrientationBuilder(
          builder: (context, orientation) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.biggest.shortestSide < 600;

                final playAreaMargin = isMobile
                    ? const EdgeInsets.all(8)
                    : const EdgeInsets.all(40);

                const divider = SizedBox(
                  width: 48,
                  child: Divider(height: 24),
                );

                final gameStatus = ref.watch(gameControllerProvider);
                final isPreparing = gameStatus == GameStatus.initializing ||
                    gameStatus == GameStatus.preparing;

                return Stack(
                  children: [
                    Positioned.fill(
                      child: switch (orientation) {
                        Orientation.landscape => Padding(
                            padding: EdgeInsets.only(
                                left: viewPadding.left + 56,
                                right: viewPadding
                                    .right), // Make room for the back button
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: IgnorePointer(
                                    ignoring: isPreparing,
                                    child: Padding(
                                      padding: playAreaMargin,
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                            maxWidth: 1000, maxHeight: 1000),
                                        child: const _PlayArea(),
                                      ),
                                    ),
                                  ),
                                ),
                                AnimatedVisibility(
                                  visible: !isPreparing,
                                  child: Container(
                                    width: 120,
                                    margin:
                                        const EdgeInsets.fromLTRB(8, 8, 8, 8),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        StatusPane(orientation: orientation),
                                        divider,
                                        ControlPane(orientation: orientation),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Orientation.portrait => Padding(
                            padding: const EdgeInsets.only(
                                top: 56), // Make room for the back button
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 32),
                                  child: Visibility(
                                    visible: !isPreparing,
                                    maintainSize: true,
                                    maintainAnimation: true,
                                    maintainState: true,
                                    child: StatusPane(orientation: orientation),
                                  ),
                                ),
                                Flexible(
                                  child: IgnorePointer(
                                    ignoring: isPreparing,
                                    child: Padding(
                                      padding: playAreaMargin,
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                            maxWidth: 1000, maxHeight: 1000),
                                        child: const _PlayArea(),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 32),
                                  child: AnimatedVisibility(
                                    visible: !isPreparing,
                                    child:
                                        ControlPane(orientation: orientation),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Future<void> _showFinishDialog(
  //     BuildContext context, SolitaireGame rules) async {
  //   final confirm = await showDialog<bool>(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (_) => ChangeNotifierProvider.value(
  //       value: context.read<GameState>(),
  //       child: const _FinishDialog(),
  //     ),
  //   );
  //
  //   if (!context.mounted) return;
  //
  //   if (confirm == true) {
  //     Navigator.popAndPushNamed(context, '/game', arguments: rules);
  //   } else {
  //     Navigator.pop(context);
  //   }
  // }
}

class _PlayArea extends ConsumerWidget {
  const _PlayArea({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(currentGameProvider);
    final cards = ref.watch(cardsOnTableProvider);
    final gameStatus = ref.watch(gameControllerProvider);
    final highlightedCards = ref.watch(hintedCardsProvider);

    return OrientationBuilder(
      builder: (context, orientation) {
        // final showMoveHighlight = context.select<SettingsManager, bool>(
        //     (s) => s.get(Settings.showMoveHighlight));
        //
        // final showAutoSolveButton = context.select<SettingsManager, bool>(
        //     (s) => s.get(Settings.showAutoSolveButton));
        //
        // final oneTapMove = context
        //     .select<SettingsManager, bool>((s) => s.get(Settings.oneTapMove));

        // if (showMoveHighlight) {
        //   final lastAction = gameState.latestAction;
        //   if (lastAction is Move && lastAction.from is! Draw) {
        //     lastMovedCards = (gameState.latestAction as Move).cards;
        //   }
        // }

        return Stack(
          alignment: Alignment.center,
          children: [
            GameTable(
              cards: cards,
              rules: game.rules,
              orientation: orientation,
              highlightedCards: highlightedCards,
              lastMovedCards: null,
              animateDistribute: gameStatus == GameStatus.preparing,
              onCardTap: (card, pile) {
                print('tapping card $card on $pile');
                final controller = ref.read(gameControllerProvider.notifier);

                switch (pile) {
                  case Tableau():
                    // if (oneTapMove) {
                    final result = _feedbackMoveResult(
                        controller.tryQuickMove(card, pile));
                    return result is MoveSuccess ? null : [card];
                  // }
                  case _:
                    return [card];
                }
                return null;
              },
              onPileTap: (pile) {
                print('tapping pile $pile');
                final controller = ref.read(gameControllerProvider.notifier);
                switch (pile) {
                  case Draw():
                    _feedbackMoveResult(controller
                        .tryMove(MoveIntent(const Draw(), const Discard())));
                    return null;

                  case Discard() || Foundation():
                    if (/* oneTapMove  && */ cards(pile).isNotEmpty) {
                      final cardToMove = cards(pile).last;
                      final result = _feedbackMoveResult(
                          controller.tryQuickMove(cardToMove, pile));
                      return result is MoveSuccess ? null : null;
                    }
                  case _:
                }
                return null;
              },
              onCardDrop: (card, from, to) {
                print('dropping card $card from $from to $to');
                final controller = ref.read(gameControllerProvider.notifier);

                final result = _feedbackMoveResult(
                  controller.tryMove(MoveIntent(from, to, card)),
                );
                return result is MoveSuccess ? null : [card];
              },
            ),
            const Positioned.fill(
              child: _UserActionIndicator(),
            ),
            // if (showAutoSolveButton)
            const Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _AutoSolveButton(),
              ),
            )
          ],
        );
      },
    );
  }

  MoveResult _feedbackMoveResult(MoveResult result) {
    if (result is MoveSuccess) {
      switch (result.move.to) {
        case Discard():
          HapticFeedback.lightImpact();
        case Tableau():
          HapticFeedback.mediumImpact();
        case Draw() || Foundation():
          HapticFeedback.heavyImpact();
      }
    }
    return result;
  }
}

class _UserActionIndicator extends StatelessWidget {
  const _UserActionIndicator({super.key});

  static const userActionIcon = {
    UserAction.undoMultiple: Icons.fast_rewind,
    UserAction.redoMultiple: Icons.fast_forward,
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final userAction = null;
    // final userAction =
    //     context.select<GameState, UserAction?>((s) => s.userAction);

    return AnimatedSwitcher(
      duration: cardMoveAnimation.duration,
      child: userAction != null
          ? Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: colorScheme.onSecondaryFixed.withOpacity(0.5),
              ),
              child: Icon(userActionIcon[userAction],
                  size: 72, color: colorScheme.secondaryFixed),
            )
          : null,
    );
  }
}

class _AutoSolveButton extends ConsumerWidget {
  const _AutoSolveButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoSolvable = ref.watch(autoSolvableProvider);
    final gameStatus = ref.watch(gameControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Shrinkable(
      show: autoSolvable && gameStatus != GameStatus.autoSolving,
      child: FloatingActionButton.extended(
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
        onPressed: () {
          ref.read(gameControllerProvider.notifier).autoSolve();
        },
        icon: const Icon(Icons.auto_fix_high),
        label: const Text('Auto solve'),
      ),
    );
  }
}

class _FinishDialog extends StatelessWidget {
  const _FinishDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    // final gameState = context.watch<GameState>();

    return AlertDialog(
      title: const Text('You win!'),
      // TODO: Workaround. As Google Fonts didn't inherit text colors from color scheme, had to do it manually here
      titleTextStyle: textTheme.headlineSmall!
          .copyWith(color: colorScheme.onPrimaryContainer),
      contentTextStyle:
          textTheme.bodyMedium!.copyWith(color: colorScheme.onSurfaceVariant),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Moves: ${0}'),
              const Spacer(),
              Text('Time: 00:00'),
            ],
          ),
          const Divider(),
          const Text('Base score'),
          Text(
            '0',
            style: textTheme.bodyLarge!
                .copyWith(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.end,
          ),
          const Divider(),
          const Text('Final score'),
          Text(
            '0',
            style:
                textTheme.headlineMedium!.copyWith(color: colorScheme.primary),
            textAlign: TextAlign.end,
          ),
        ],
      ),
      actions: [
        FilledButton.tonal(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: const Text('Quit'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
          child: const Text('Play again'),
        ),
      ],
    );
  }
}
