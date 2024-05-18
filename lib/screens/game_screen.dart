import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../animations.dart';
import '../models/game_state.dart';
import '../models/pile.dart';
import '../models/rules/rules.dart';
import '../providers/settings.dart';
import '../widgets/background.dart';
import '../widgets/control_pane.dart';
import '../widgets/debug_control_pane.dart';
import '../widgets/debug_hud.dart';
import '../widgets/game_table.dart';
import '../widgets/shrinkable.dart';
import '../widgets/status_pane.dart';
import '../widgets/touch_focusable.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero * timeDilation, () {
      final gameState = context.read<GameState>();
      if (gameState.status == GameStatus.initiializing ||
          gameState.status == GameStatus.ended) {
        gameState.startNewGame();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isWinning = context.select<GameState, bool>((s) => s.isWinning);

    return Scaffold(
      backgroundColor: colorScheme.primaryContainer,
      body: RippleBackground(
        color: isWinning
            ? colorScheme.surfaceContainerLowest
            : colorScheme.primaryContainer,
        child: SafeArea(
          child: OrientationBuilder(
            builder: (context, orientation) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.biggest.shortestSide < 600;

                  final outerMargin = isMobile
                      ? const EdgeInsets.all(8)
                      : const EdgeInsets.all(40);

                  final divider = SizedBox(
                    width: 48,
                    child: Divider(
                      height: 24,
                      color: colorScheme.onPrimaryContainer.withOpacity(0.3),
                    ),
                  );

                  final isPreparing =
                      context.select<GameState, bool>((s) => s.isPreparing);

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: switch (orientation) {
                          Orientation.landscape => Padding(
                              padding: outerMargin,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: TouchFocusable(
                                      active: !isPreparing,
                                      opacityWhenUnfocus: 1,
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                            maxWidth: 1000, maxHeight: 1000),
                                        child: const _PlayArea(),
                                      ),
                                    ),
                                  ),
                                  TouchFocusable(
                                    active: !isPreparing,
                                    opacityWhenUnfocus: 0,
                                    child: Container(
                                      width: 120,
                                      margin: const EdgeInsets.only(left: 32),
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
                              padding: outerMargin,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 32),
                                    child: TouchFocusable(
                                      active: !isPreparing,
                                      opacityWhenUnfocus: 0,
                                      child:
                                          StatusPane(orientation: orientation),
                                    ),
                                  ),
                                  Flexible(
                                    child: TouchFocusable(
                                      active: !isPreparing,
                                      opacityWhenUnfocus: 1,
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                            maxWidth: 1000, maxHeight: 1000),
                                        child: const _PlayArea(),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 32),
                                    child: TouchFocusable(
                                      active: !isPreparing,
                                      opacityWhenUnfocus: 0,
                                      child:
                                          ControlPane(orientation: orientation),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        },
                      ),
                      if (context
                          .watch<SettingsManager>()
                          .get(Settings.showDebugPanel))
                        switch (orientation) {
                          Orientation.landscape => const Align(
                              alignment: Alignment.centerRight,
                              child: SizedBox(
                                width: 200,
                                height: double.infinity,
                                child: DebugHUD(),
                              ),
                            ),
                          Orientation.portrait => const Align(
                              alignment: Alignment.bottomCenter,
                              child: SizedBox(
                                width: double.infinity,
                                height: 250,
                                child: DebugHUD(),
                              ),
                            ),
                        },
                      const Align(
                        alignment: Alignment.bottomLeft,
                        child: DebugControlPane(),
                      )
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PlayArea extends StatelessWidget {
  const _PlayArea({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    return OrientationBuilder(builder: (context, orientation) {
      final options = LayoutOptions(
        orientation: orientation,
        mirror: false,
      );

      final cards = gameState.cardsOnTable;

      PlayCardList? lastMovedCards, highlightedCards;

      final showMoveHighlight = context.select<SettingsManager, bool>(
          (s) => s.get(Settings.showMoveHighlight));

      if (showMoveHighlight) {
        final lastAction = gameState.latestAction;
        if (lastAction is Move) {
          if (lastAction.from is! Draw && lastAction is! Draw) {
            lastMovedCards = (gameState.latestAction as Move).cards;
          }
        }
        highlightedCards = gameState.hintedCards;
      }

      return Stack(
        alignment: Alignment.center,
        children: [
          GameTable(
            cards: cards,
            layout: gameState.rules.getLayout(options),
            highlightedCards: highlightedCards,
            lastMovedCards: lastMovedCards,
            animatedDistribute: gameState.status == GameStatus.preparing,
            onCardTap: (card, pile) {
              print('tapping card $card on $pile');
              final gameState = context.read<GameState>();

              switch (pile) {
                case Tableau():
                  final result =
                      _feedbackMoveResult(gameState.tryQuickPlace(card, pile));
                  return result is MoveSuccess;
                case _:
                  return false;
              }
            },
            onPileTap: (pile) {
              print('tapping pile $pile');
              final gameState = context.read<GameState>();

              switch (pile) {
                case Draw():
                  _feedbackMoveResult(gameState
                      .tryMove(MoveIntent(const Draw(), const Discard())));
                  return true;

                case Discard() || Foundation():
                  if (cards(pile).isNotEmpty) {
                    final cardToMove = cards(pile).last;
                    final result = _feedbackMoveResult(
                        gameState.tryQuickPlace(cardToMove, pile));
                    return result is MoveSuccess;
                  }
                case _:
              }
              return false;
            },
            onCardDrop: (card, from, to) {
              print('dropping card $card from $from to $to');
              final gameState = context.read<GameState>();

              final result = _feedbackMoveResult(
                gameState.tryMove(
                  MoveIntent(from, to, card),
                ),
              );
              return result is MoveSuccess;
            },
          ),
          const Positioned.fill(
            child: _UserActionIndicator(),
          ),
          const Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _AutoSolveButton(),
            ),
          )
        ],
      );
    });
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
    final userAction =
        context.select<GameState, UserAction?>((s) => s.userAction);

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

class _AutoSolveButton extends StatefulWidget {
  const _AutoSolveButton({super.key});

  @override
  State<_AutoSolveButton> createState() => _AutoSolveButtonState();
}

class _AutoSolveButtonState extends State<_AutoSolveButton> {
  @override
  Widget build(BuildContext context) {
    final canAutoSolve = context.select<GameState, bool>((s) => s.canAutoSolve);
    final status = context.select<GameState, GameStatus>((s) => s.status);
    final colorScheme = Theme.of(context).colorScheme;

    return Shrinkable(
      show: canAutoSolve && status != GameStatus.autoSolving,
      child: FloatingActionButton.extended(
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
        onPressed: () {
          context.read<GameState>().startAutoSolve();
        },
        icon: const Icon(Icons.auto_fix_high),
        label: const Text('Auto solve'),
      ),
    );
  }
}
