import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../animations.dart';
import '../models/game_state.dart';
import '../models/pile.dart';
import '../providers/settings.dart';
import '../widgets/ripple_background.dart';
import '../widgets/control_pane.dart';
import '../widgets/debug_control_pane.dart';
import '../widgets/debug_hud.dart';
import '../widgets/game_table.dart';
import '../widgets/shrinkable.dart';
import '../widgets/solitaire_theme.dart';
import '../widgets/status_pane.dart';

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
    final theme = SolitaireTheme.of(context);
    final isWinning = context.select<GameState, bool>((s) => s.isWinning);

    final viewPadding = MediaQuery.of(context).viewPadding;

    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
      ),
      extendBodyBehindAppBar: true,
      body: RippleBackground(
        decoration: isWinning
            ? BoxDecoration(color: theme.winningBackgroundColor)
            : BoxDecoration(color: theme.tableBackgroundColor),
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

                final isPreparing =
                    context.select<GameState, bool>((s) => s.isPreparing);

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
                                Visibility(
                                  visible: !isPreparing,
                                  maintainSize: true,
                                  maintainAnimation: true,
                                  maintainState: true,
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
                                  child: Visibility(
                                    visible: !isPreparing,
                                    maintainSize: true,
                                    maintainAnimation: true,
                                    maintainState: true,
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
}

class _PlayArea extends StatelessWidget {
  const _PlayArea({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    return OrientationBuilder(builder: (context, orientation) {
      final cards = gameState.cardsOnTable;

      PlayCardList? lastMovedCards, highlightedCards;

      final showMoveHighlight = context.select<SettingsManager, bool>(
          (s) => s.get(Settings.showMoveHighlight));

      final showAutoSolveButton = context.select<SettingsManager, bool>(
          (s) => s.get(Settings.showAutoSolveButton));

      final oneTapMove = context
          .select<SettingsManager, bool>((s) => s.get(Settings.oneTapMove));

      if (showMoveHighlight) {
        final lastAction = gameState.latestAction;
        if (lastAction is Move && lastAction.from is! Draw) {
          lastMovedCards = (gameState.latestAction as Move).cards;
        }
      }

      highlightedCards = gameState.hintedCards;

      return Stack(
        alignment: Alignment.center,
        children: [
          GameTable(
            cards: cards,
            rules: gameState.rules,
            orientation: orientation,
            highlightedCards: highlightedCards,
            lastMovedCards: lastMovedCards,
            animateDistribute: gameState.status == GameStatus.preparing,
            onCardTap: (card, pile) {
              print('tapping card $card on $pile');
              final gameState = context.read<GameState>();

              switch (pile) {
                case Tableau():
                  if (oneTapMove) {
                    final result = _feedbackMoveResult(
                        gameState.tryQuickPlace(card, pile));
                    return result is MoveSuccess ? null : [card];
                  }
                case _:
                  return [card];
              }
              return null;
            },
            onPileTap: (pile) {
              print('tapping pile $pile');
              final gameState = context.read<GameState>();

              switch (pile) {
                case Draw():
                  _feedbackMoveResult(gameState
                      .tryMove(MoveIntent(const Draw(), const Discard())));
                  return null;

                case Discard() || Foundation():
                  if (oneTapMove && cards(pile).isNotEmpty) {
                    final cardToMove = cards(pile).last;
                    final result = _feedbackMoveResult(
                        gameState.tryQuickPlace(cardToMove, pile));
                    return result is MoveSuccess ? null : null;
                  }
                case _:
              }
              return null;
            },
            onCardDrop: (card, from, to) {
              print('dropping card $card from $from to $to');
              final gameState = context.read<GameState>();

              final result = _feedbackMoveResult(
                gameState.tryMove(
                  MoveIntent(from, to, card),
                ),
              );
              return result is MoveSuccess ? null : [card];
            },
          ),
          const Positioned.fill(
            child: _UserActionIndicator(),
          ),
          if (showAutoSolveButton)
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
