import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../animations.dart';
import '../../models/game/solitaire.dart';
import '../../models/game_status.dart';
import '../../models/game_theme.dart';
import '../../models/play_data.dart';
import '../../providers/feedback.dart';
import '../../providers/game_logic.dart';
import '../../providers/game_selection.dart';
import '../../providers/game_storage.dart';
import '../../providers/settings.dart';
import '../../providers/shared_preferences.dart';
import '../../providers/themes.dart';
import '../../widgets/animated_visibility.dart';
import '../../widgets/bottom_padded.dart';
import '../../widgets/celebration_effect.dart';
import '../../widgets/message_overlay.dart';
import '../../widgets/mini_toast.dart';
import '../../widgets/ripple_background.dart';
import '../../widgets/screen_visibility.dart';
import '../game_select/widgets/continue_failed_dialog.dart';
import 'widgets/control_pane.dart';
import 'widgets/finish_dialog.dart';
import 'widgets/game_menu.dart';
import 'widgets/play_area.dart';
import 'widgets/screen_rotate_button.dart';
import 'widgets/status_pane.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MessageOverlay(
      child: GameScreenBody(),
    );
  }
}

class GameScreenBody extends ConsumerStatefulWidget {
  const GameScreenBody({super.key});

  @override
  ConsumerState<GameScreenBody> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreenBody>
    with RouteAware, WidgetsBindingObserver, ScreenVisibility {
  bool _isStarted = false;

  @override
  void initState() {
    super.initState();
    _tryContinueGame();
  }

  void _tryContinueGame() {
    Future.microtask(() async {
      final allGames = ref.read(allSolitaireGamesProvider);

      SolitaireGame? lastPlayedGame;

      try {
        final continuableGames =
            await ref.read(continuableGamesProvider.future);

        // Wait for shared prefs to load first
        await ref.read(sharedPreferenceProvider.future);
        final lastPlayedGameTag = ref.read(settingsLastPlayedGameProvider);

        lastPlayedGame =
            allGames.firstWhereOrNull((game) => game.tag == lastPlayedGameTag);

        if (lastPlayedGame != null) {
          if (continuableGames.contains(lastPlayedGame)) {
            // Continue with last opened game
            final gameData = await ref
                .read(gameStorageProvider.notifier)
                .restoreQuickSave(lastPlayedGame);

            _startExistingGame(gameData);
          } else {
            _startNewGame(lastPlayedGame);
          }
        } else {
          _startNewGame(allGames.first);
        }
        Future.delayed(themeChangeAnimation.duration ~/ 2, () {
          setState(() {
            _isStarted = true;
          });
        });
      } catch (error) {
        setState(() {
          _isStarted = true;
        });
        if (!mounted) return;
        final response = await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => ContinueFailedDialog(error: error),
        );
        if (response == true) {
          _startNewGame(lastPlayedGame ?? allGames.first);
        } else {
          if (!mounted) return;
          context.go('/select');
        }
      }
    });
  }

  void _startExistingGame(GameData gameData) {
    ref.read(gameControllerProvider.notifier).restore(gameData);

    Future.delayed(
      themeChangeAnimation.duration,
      () => _showStartingSnackBar(context, gameData.metadata.kind,
          isContinueGame: true),
    );
  }

  void _startNewGame(SolitaireGame game) {
    ref.read(gameControllerProvider.notifier).startNew(game);

    Future.delayed(
      themeChangeAnimation.duration,
      () => _showStartingSnackBar(context, game, isContinueGame: false),
    );
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
    final isFinished = ref
        .watch(gameControllerProvider.select((s) => s == GameStatus.finished));

    ref.listen(gameControllerProvider, (_, newStatus) {
      if (newStatus == GameStatus.finished) {
        Future.microtask(() async {
          _showFinishDialog(context);
          final game = ref.read(currentGameProvider);
          ref.read(gameStorageProvider.notifier).deleteQuickSave(game.kind);
        });
      }
    });
    ref.listen(currentGameProvider, (previousGame, newGame) {
      if (previousGame != null &&
          previousGame.seed.isNotEmpty &&
          previousGame.startedTime != newGame.startedTime) {
        Future.delayed(standardAnimation.duration, () {
          ref.read(themeBaseRandomizeColorProvider.notifier).tryShuffleColor();
        });
      }
    });

    ref.watch(feedbackProvider);

    return CelebrationEffect(
      enabled: isFinished,
      child: OrientationBuilder(
        builder: (context, orientation) {
          return RippleBackground(
            decoration: isFinished
                ? BoxDecoration(
                    color: Theme.of(context).gameTheme.winningBackgroundColor)
                : BoxDecoration(
                    color: Theme.of(context).gameTheme.tableBackgroundColor),
            child: SafeArea(
              child: LayoutBuilder(
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
                    child: switch (orientation) {
                      Orientation.landscape => Row(
                          children: [
                            const Column(
                              children: [
                                GameMenuButton(),
                                ScreenRotateButton()
                              ],
                            ),
                            Expanded(
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
                          ],
                        ),
                      Orientation.portrait => Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GameMenuButton(),
                                ScreenRotateButton()
                              ],
                            ),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 32),
                                    child: AnimatedVisibility(
                                      visible: !isPreparing,
                                      child:
                                          StatusPane(orientation: orientation),
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
                                        orientation: orientation,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _showStartingSnackBar(BuildContext context, SolitaireGame game,
      {required bool isContinueGame}) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    if (!mounted) return;

    final overlay = MiniToast(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          isContinueGame
              ? const Text('Continuing last game')
              : const Text('Starting game'),
          const SizedBox(height: 4),
          Text(
            game.name,
            style: textTheme.titleLarge!
                .copyWith(color: colorScheme.inversePrimary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    MessageOverlay.of(context).show(overlay);
  }

  Future<void> _showFinishDialog(BuildContext context) async {
    if (!context.mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const FinishDialog(),
    );

    if (!context.mounted) return;

    if (confirm == true) {
      final game = ref.read(currentGameProvider);
      ref.read(gameControllerProvider.notifier).startNew(game.kind);
    } else {
      // Navigator.pop(context);
    }
  }
}
