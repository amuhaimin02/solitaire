import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../animations.dart';
import '../../models/game/solitaire.dart';
import '../../models/game_status.dart';
import '../../providers/feedback.dart';
import '../../providers/game_logic.dart';
import '../../providers/game_selection.dart';
import '../../providers/game_storage.dart';
import '../../providers/settings.dart';
import '../../services/shared_preferences.dart';
import '../../widgets/animated_visibility.dart';
import '../../widgets/bottom_padded.dart';
import '../../widgets/ripple_background.dart';
import '../../widgets/screen_visibility.dart';
import '../../widgets/solitaire_theme.dart';
import '../../widgets/status_pane.dart';
import 'widgets/control_pane.dart';
import 'widgets/finish_dialog.dart';
import 'widgets/game_menu.dart';
import 'widgets/play_area.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with RouteAware, WidgetsBindingObserver, ScreenVisibility {
  bool _isStarted = false;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    Future.microtask(() async {
      bool isContinueGame;
      SolitaireGame startedGame;

      try {
        final allGames = ref.read(allSolitaireGamesProvider);

        final continuableGames =
            await ref.read(continuableGamesProvider.future);

        // Wait for shared prefs to load first
        await ref.read(sharedPreferenceProvider.future);
        final lastPlayedGameTag = ref.read(settingsLastPlayedGameProvider);

        final lastPlayedGame =
            allGames.firstWhereOrNull((game) => game.tag == lastPlayedGameTag);

        if (lastPlayedGame != null) {
          if (continuableGames.contains(lastPlayedGame)) {
            // Continue with last opened game
            final gameData = await ref
                .read(gameStorageProvider.notifier)
                .restoreQuickSave(lastPlayedGame);

            ref.read(gameControllerProvider.notifier).restore(gameData);
            isContinueGame = true;
            startedGame = gameData.metadata.game;
          } else {
            ref.read(gameControllerProvider.notifier).startNew(lastPlayedGame);
            isContinueGame = false;
            startedGame = lastPlayedGame;
          }
        } else {
          ref.read(gameControllerProvider.notifier).startNew(allGames.first);
          isContinueGame = false;
          startedGame = allGames.first;
        }
        // Wait for animation to end, also for context to be initialized with theme
        Future.delayed(
          themeChangeAnimation.duration,
          () {
            if (mounted) {
              _showStartingSnackBar(context, startedGame, isContinueGame);
            }
          },
        );
      } finally {
        Future.delayed(themeChangeAnimation.duration * 0.5, () {
          setState(() {
            _isStarted = true;
          });
        });
      }
    });
  }

  @override
  void onEnter() {
    if (ref.read(gameControllerProvider) == GameStatus.started) {
      ref.read(playTimeProvider.notifier).resume();
    }
    print('Game resumed');
  }

  @override
  void onLeave() {
    if (ref.read(gameControllerProvider) != GameStatus.started) {
      print('Game not started. Skipping');
      return;
    }
    final gameData = ref.read(gameControllerProvider.notifier).suspend();
    ref.read(gameStorageProvider.notifier).quickSave(gameData);
    print('Game saved');
  }

  @override
  Widget build(BuildContext context) {
    final theme = SolitaireTheme.of(context);
    final viewPadding = MediaQuery.of(context).viewPadding;
    final isFinished = ref
        .watch(gameControllerProvider.select((s) => s == GameStatus.finished));

    ref.listen(gameControllerProvider, (_, newStatus) {
      if (newStatus == GameStatus.finished) {
        Future.microtask(() async {
          _showFinishDialog(context);
          final game = ref.read(currentGameProvider);
          ref.read(gameStorageProvider.notifier).deleteQuickSave(game.game);
        });
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
        child: BottomPadded(
          child: OrientationBuilder(
            builder: (context, orientation) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final colorScheme = Theme.of(context).colorScheme;
                  // final isMobile = constraints.biggest.shortestSide < 600;

                  const playAreaMargin = EdgeInsets.all(8);

                  final divider = SizedBox(
                    width: 48,
                    child: Divider(height: 24, color: colorScheme.onSurface),
                  );

                  final gameStatus = ref.watch(gameControllerProvider);
                  final isPreparing = gameStatus == GameStatus.initializing ||
                      gameStatus == GameStatus.preparing;

                  return AnimatedVisibility(
                    visible: _isStarted,
                    duration: themeChangeAnimation.duration,
                    child: Stack(
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
                                                maxWidth: 1000,
                                                maxHeight: 1000),
                                            child: PlayArea(
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
                                        margin: const EdgeInsets.fromLTRB(
                                            8, 8, 8, 8),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            StatusPane(
                                                orientation: orientation),
                                            divider,
                                            ControlPane(
                                                orientation: orientation),
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
                                      padding:
                                          const EdgeInsets.only(bottom: 32),
                                      child: AnimatedVisibility(
                                        visible: !isPreparing,
                                        child: StatusPane(
                                            orientation: orientation),
                                      ),
                                    ),
                                    Flexible(
                                      child: IgnorePointer(
                                        ignoring: isPreparing,
                                        child: Padding(
                                          padding: playAreaMargin,
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                                maxWidth: 1000,
                                                maxHeight: 1000),
                                            child: PlayArea(
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
                                        child: ControlPane(
                                            orientation: orientation),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showStartingSnackBar(
      BuildContext context, SolitaireGame game, bool continueGame) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          continueGame
              ? const Text('Continuing last game')
              : const Text('Starting game'),
          Text(
            game.name,
            style: textTheme.titleMedium!
                .copyWith(color: colorScheme.inversePrimary),
          ),
        ],
      ),
      action: SnackBarAction(
        label: 'Change',
        onPressed: () {
          context.go('/select');
        },
      ),
    ));
  }

  Future<void> _showFinishDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const FinishDialog(),
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