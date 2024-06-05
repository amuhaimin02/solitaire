import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../animations.dart';
import '../models/action.dart';
import '../models/card.dart';
import '../models/game_status.dart';
import '../models/move_result.dart';
import '../models/pile_check.dart';
import '../models/play_data.dart';
import '../models/user_action.dart';
import '../providers/feedback.dart';
import '../providers/game_logic.dart';
import '../providers/game_selection.dart';
import '../providers/game_storage.dart';
import '../providers/settings.dart';
import '../utils/types.dart';
import '../widgets/animated_visibility.dart';
import '../widgets/control_pane.dart';
import '../widgets/debug_pane.dart';
import '../widgets/fixes.dart';
import '../widgets/game_table.dart';
import '../widgets/ripple_background.dart';
import '../widgets/route_observer.dart';
import '../widgets/shrinkable.dart';
import '../widgets/solitaire_theme.dart';
import '../widgets/status_pane.dart';
import 'game_menu.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with RouteAware, WidgetsBindingObserver, RouteObserved {
  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    Future.microtask(() async {
      if (await ref.read(gameStorageProvider.notifier).hasQuickSave()) {
        // Continue with last opened game
        final gameData =
            await ref.read(gameStorageProvider.notifier).restoreQuickSave();
        if (mounted) {
          // Wait for animation to end, also for context to be initialized with theme
          Future.delayed(
            themeChangeAnimation.duration,
            () => _showContinueSnackBar(context, gameData),
          );
        }

        ref.read(gameControllerProvider.notifier).restore(gameData);
      } else {
        ref.read(gameControllerProvider.notifier).startNew(
              ref.read(allSolitaireGamesProvider).first,
            );
      }
    });
  }

  @override
  void onEnter() {
    if (ref.read(gameControllerProvider) == GameStatus.started) {
      ref.read(playTimeProvider.notifier).resume();
      print('resuming');
    }
  }

  @override
  void onLeave() {
    if (ref.read(gameControllerProvider) != GameStatus.started) {
      print('Game not started. Skipping');
      return;
    }
    final gameData = ref.read(gameControllerProvider.notifier).suspend();
    ref.read(gameStorageProvider.notifier).quickSave(gameData);
  }

  @override
  Widget build(BuildContext context) {
    final theme = SolitaireTheme.of(context);
    final viewPadding = MediaQuery.of(context).viewPadding;
    final isFinished = ref
        .watch(gameControllerProvider.select((s) => s == GameStatus.finished));

    ref.listen(gameControllerProvider, (_, newStatus) {
      if (newStatus == GameStatus.finished) {
        Future.microtask(() => _showFinishDialog(context));
      }
    });

    ref.watch(feedbackProvider);

    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        leading: const GameMenuButton(),
      ),
      extendBodyBehindAppBar: true,
      body: RippleBackground(
        decoration: isFinished
            ? BoxDecoration(color: theme.winningBackgroundColor)
            : BoxDecoration(color: theme.backgroundColor),
        child: OrientationBuilder(
          builder: (context, orientation) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final colorScheme = Theme.of(context).colorScheme;
                // final isMobile = constraints.biggest.shortestSide < 600;

                const playAreaMargin = EdgeInsets.all(8);

                final divider = SizedBox(
                  width: 48,
                  child: Divider(height: 24, color: colorScheme.outline),
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
                                        child: _PlayArea(
                                          orientation: orientation,
                                        ),
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
                                  child: AnimatedVisibility(
                                    visible: !isPreparing,
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
                                        child: _PlayArea(
                                          orientation: orientation,
                                        ),
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
                    const Align(
                      alignment: Alignment.bottomLeft,
                      child: DebugPane(),
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

  void _showContinueSnackBar(BuildContext context, GameData data) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Continuing last game'),
          Text(
            data.metadata.game.name,
            style: textTheme.titleMedium!
                .copyWith(color: colorScheme.inversePrimary),
          ),
        ],
      ),
    ));
  }

  Future<void> _showFinishDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _FinishDialog(),
    );

    if (!context.mounted) return;

    if (confirm == true) {
      final game = ref.read(currentGameProvider);
      ref.read(gameControllerProvider.notifier).startNew(game.game);
    } else {
      // Navigator.pop(context);
    }
  }
}

class _PlayArea extends ConsumerWidget {
  const _PlayArea({super.key, required this.orientation});

  final Orientation orientation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(currentGameProvider);
    final table = ref.watch(playTableStateProvider);
    final status = ref.watch(gameControllerProvider);
    final highlightedCards = ref.watch(hintedCardsProvider);

    return OrientationBuilder(
      builder: (context, localOrientation) {
        final showLastMoves = ref.watch(settingsShowLastMoveProvider);

        final showAutoSolveButton =
            ref.watch(settingsShowAutoSolveButtonProvider);

        List<PlayCard>? lastMovedCards;

        if (showLastMoves) {
          final lastMove = ref.watch(lastActionProvider).move;
          if (lastMove != null) {
            lastMovedCards = lastMove.cards;
          }
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            GameTable(
              table: table,
              game: game.game,
              orientation: orientation,
              highlightedCards: highlightedCards,
              lastMovedCards: lastMovedCards,
              animateDistribute: status == GameStatus.preparing,
              canDragCards: (cards, from) {
                final pileInfo = game.game.piles.get(from);

                return PileCheck.checkAll(
                    pileInfo.pickable, from, null, cards, table) is PileCheckOK;
              },
              onCardTap: (card, pile) {
                print('card tap $card $pile');
                ScaffoldMessenger.of(context).clearSnackBars();
                final controller = ref.read(gameControllerProvider.notifier);

                final pileInfo = game.game.piles.get(pile);
                if (pileInfo.onTap != null) {
                  controller.tryMove(MoveIntent(pile, pile));
                  return null;
                }
                if (card != null) {
                  final result = controller.tryQuickMove(card, pile);
                  return result is MoveSuccess ? null : [card];
                }
                return null;
              },
              onCardDrop: (card, from, to) {
                final controller = ref.read(gameControllerProvider.notifier);

                final result = controller.tryMove(MoveIntent(from, to, card));

                ScaffoldMessenger.of(context).clearSnackBars();
                if (result is MoveForbidden) {
                  _showMoveForbiddenPopup(context, result);
                }
                return null;
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
      },
    );
  }

  void _showMoveForbiddenPopup(BuildContext context, MoveForbidden move) {
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        move.reason,
        style: TextStyle(color: colorScheme.onError),
      ),
      backgroundColor: colorScheme.error,
    ));
  }
}

class _UserActionIndicator extends ConsumerWidget {
  const _UserActionIndicator({super.key});

  static const userActionIcon = {
    UserActionOptions.undoMultiple: Icons.fast_rewind,
    UserActionOptions.redoMultiple: Icons.fast_forward,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    final userAction = ref.watch(userActionProvider);

    return AnimatedSwitcher(
      duration: cardMoveAnimation.duration,
      child: userAction != null
          ? Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: colorScheme.inverseSurface,
              ),
              child: Icon(
                userActionIcon[userAction],
                size: 72,
                color: colorScheme.onInverseSurface,
              ),
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
      show: autoSolvable && gameStatus == GameStatus.started,
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

class _FinishDialog extends ConsumerWidget {
  const _FinishDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final moves = ref.watch(moveCountProvider);
    final playTime = ref.watch(playTimeProvider);
    final score = ref.watch(scoreProvider);

    return DialogThemeFix(
      child: AlertDialog(
        title: const Text('You win!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Moves: $moves'),
                const Spacer(),
                Text('Time: ${playTime.toMMSSString()}'),
              ],
            ),
            const Divider(),
            const Text('Base score'),
            Text(
              '$score',
              style: textTheme.bodyLarge!
                  .copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.end,
            ),
            const Divider(),
            const Text('Final score'),
            Text(
              '$score',
              style: textTheme.headlineMedium!
                  .copyWith(color: colorScheme.primary),
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
      ),
    );
  }
}
