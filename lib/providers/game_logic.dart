import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../animations.dart';
import '../models/action.dart';
import '../models/card.dart';
import '../models/card_distribute_animation.dart';
import '../models/card_list.dart';
import '../models/game/solitaire.dart';
import '../models/game_status.dart';
import '../models/move_action.dart';
import '../models/move_attempt.dart';
import '../models/move_check.dart';
import '../models/move_event.dart';
import '../models/move_result.dart';
import '../models/pile.dart';
import '../models/play_data.dart';
import '../models/play_table.dart';
import '../models/score_summary.dart';
import '../models/user_action.dart';
import '../utils/collections.dart';
import '../utils/prng.dart';
import '../utils/stopwatch.dart';
import '../utils/types.dart';
import 'game_move_history.dart';
import 'game_selection.dart';
import 'settings.dart';

part 'game_logic.g.dart';

@Riverpod(keepAlive: true)
SettableStopwatch stopwatch(StopwatchRef ref) {
  return SettableStopwatch();
}

@riverpod
class PlayTime extends _$PlayTime {
  @override
  Duration build() {
    return ref.read(stopwatchProvider).elapsed;
  }

  void set(Duration playTime) {
    ref.read(stopwatchProvider).startDuration = playTime;
  }

  void restart() {
    ref.read(stopwatchProvider)
      ..reset()
      ..start();
    ref.invalidateSelf();
  }

  void resume() {
    ref.read(stopwatchProvider).start();
    ref.invalidateSelf();
  }

  void pause() {
    ref.read(stopwatchProvider).stop();
    ref.invalidateSelf();
  }

  void stop() {
    ref.read(stopwatchProvider)
      ..stop()
      ..reset();
    ref.invalidateSelf();
  }
}

@riverpod
bool playTimeIsRunning(PlayTimeIsRunningRef ref) {
  ref.watch(playTimeProvider);
  return ref.watch(stopwatchProvider).isRunning;
}

@riverpod
class CurrentGame extends _$CurrentGame {
  // TODO: Make nullable
  @override
  GameMetadata build() {
    return GameMetadata(
      game: ref.watch(allSolitaireGamesProvider).first,
      startedTime: DateTime.now(),
      randomSeed: '1234',
    );
  }

  void start(GameMetadata game) {
    state = game;
  }
}

@riverpod
class GameController extends _$GameController {
  @override
  GameStatus build() {
    ref.listenSelf((_, newStatus) {
      if (newStatus == GameStatus.finished) {
        ref.read(playTimeProvider.notifier).pause();
      }
    });
    return GameStatus.ready;
  }

  Future<void> startNew(SolitaireGame game) async {
    // Prepare a new game to start
    final newPlayData = GameMetadata(
      game: game,
      startedTime: DateTime.now(),
      randomSeed: CustomPRNG.generateSeed(length: 12),
    );
    ref.read(currentGameProvider.notifier).start(newPlayData);

    // Setup draw piles for the new game
    final initialTable = _setupPiles();
    ref
        .read(moveHistoryProvider.notifier)
        .createNew(initialTable, const GameStart());
    state = GameStatus.initializing;
    await Future.delayed(cardMoveAnimation.duration * timeDilation * 2);

    // Start distribute cards according to game
    final setupTable = _setupCards(initialTable);
    state = GameStatus.preparing;
    ref
        .read(moveHistoryProvider.notifier)
        .add(setupTable, const GameStart(), isAutoMove: true);

    // Wait for animation to finish (this ties up to game table animation logic
    await Future.delayed(
        _estimateDistributionAnimationTime(setupTable) * timeDilation);

    ref.read(playTimeProvider.notifier).restart();
    state = GameStatus.started;

    if (ref.read(settingsUseAutoPremoveProvider)) {
      _doPremove();
    }
  }

  void restart() async {
    ref.read(moveHistoryProvider.notifier).restart();
    ref.read(playTimeProvider.notifier).restart();
  }

  GameData suspend() {
    // Stop timer to release resources
    ref.read(playTimeProvider.notifier).pause();

    return GameData(
      metadata: ref.read(currentGameProvider),
      state: GameState(
        playTime: ref.read(playTimeProvider),
        moveCursor: ref.read(moveCursorProvider),
      ),
      history: ref.read(moveRecordListProvider),
    );
  }

  void restore(GameData gameData) {
    ref.read(currentGameProvider.notifier).start(gameData.metadata);
    ref.read(playTimeProvider.notifier).set(gameData.state.playTime);
    ref
        .read(moveHistoryProvider.notifier)
        .restore(gameData.state.moveCursor, gameData.history);

    // Start timer immediately
    ref.read(playTimeProvider.notifier).resume();

    state = GameStatus.started;
  }

  bool highlightHints() {
    final table = ref.read(currentTableProvider);

    final movableCards = <PlayCard>[];
    for (final (card, from) in _getAllMovableCards()) {
      if (tryQuickMove(card, from, doMove: false) is MoveSuccess) {
        movableCards.add(card);
      }
    }
    if (movableCards.isEmpty) {
      for (final s in table.allPilesOfType<Stock>()) {
        final cardsOnStock = table.get(s);
        if (cardsOnStock.isNotEmpty) {
          movableCards.add(cardsOnStock.last);
        }
      }
    }

    if (movableCards.isNotEmpty) {
      ref
          .read(hintedCardsProvider.notifier)
          .highlight(PlayCardList(movableCards));
      return true;
    } else {
      return false;
    }
  }

  MoveResult tryMove(
    MoveIntent move, {
    bool doMove = true,
    bool doAfterMove = true,
    bool isAutoMove = false,
  }) {
    final game = ref.read(currentGameProvider);
    final moveState = ref.read(currentMoveProvider)?.state;
    final lastAction = ref.read(currentActionProvider);

    PlayTable table = ref.read(currentTableProvider);

    final originPileInfo = game.game.setup.get(move.from);

    final targetPileInfo = game.game.setup.get(move.to);

    final cardToMove = move.card;
    final cardsInPile = table.get(move.from);

    final PlayCardList cardsToPick;
    if (cardToMove != null) {
      cardsToPick = cardsInPile.getLastFromCard(cardToMove);
    } else {
      if (cardsInPile.isEmpty) {
        cardsToPick = const PlayCardList.empty();
      } else {
        cardsToPick = PlayCardList([cardsInPile.last]);
      }
    }

    MoveActionResult result = MoveActionNoChange(table: table);

    if (originPileInfo.onTap != null && move.from == move.to) {
      if (originPileInfo.canTap != null) {
        final canTapResult = MoveCheck.checkAll(
          originPileInfo.canTap,
          MoveCheckArgs(
            pile: move.from,
            cards: cardsToPick,
            table: table,
            moveState: moveState,
          ),
        );
        if (canTapResult is MoveCheckFail) {
          return MoveForbidden(
            'Cannot make the move.\n${canTapResult.reason?.errorMessage}',
          );
        }
      }

      result = MoveAction.runAll(
        originPileInfo.onTap,
        MoveActionArgs(
          pile: move.from,
          table: table,
          metadata: game,
          moveState: moveState,
          lastAction: lastAction,
        ),
      );
    } else {
      if (move.from == move.to) {
        return const MoveForbidden('Cannot move cards back to its pile');
      }

      if (result is! MoveActionHandled || result.action == null) {
        if (cardsToPick.isEmpty) {
          return MoveNotDone('No cards to pick', null, move.from);
        }

        final canPickResult = MoveCheck.checkAll(
          originPileInfo.pickable,
          MoveCheckArgs(
            pile: move.from,
            cards: cardsToPick,
            table: table,
            moveState: moveState,
          ),
        );
        if (canPickResult is MoveCheckFail) {
          return MoveForbidden(
            'Cannot pick the card(s) there.\n${canPickResult.reason?.errorMessage}',
          );
        }

        final canPlaceResult = MoveCheck.checkAll(
          targetPileInfo.placeable,
          MoveCheckArgs(
            pile: move.to,
            originPile: move.from,
            cards: cardsToPick,
            table: table,
            moveState: moveState,
          ),
        );

        if (canPlaceResult is MoveCheckFail) {
          return MoveForbidden(
              'Cannot place the card(s) here.\n${canPlaceResult.reason?.errorMessage}');
        }

        result = MoveAction.runAll(
          [MoveNormally(to: move.to, count: cardsToPick.length)],
          MoveActionArgs(
            pile: move.from,
            table: table,
            metadata: game,
            moveState: moveState,
            lastAction: lastAction,
          ),
        );
      }
    }
    for (final (pile, props) in game.game.setup.items) {
      if (props.afterMove != null) {
        result = MoveAction.chain(
          result,
          props.afterMove,
          MoveActionArgs(
            pile: pile,
            table: table,
            metadata: game,
            moveState: moveState,
            lastAction: lastAction,
          ),
        );
      }
    }

    if (result is! MoveActionHandled) {
      return MoveNotDone('Move result is not successful', null, move.from);
    }

    Action? targetAction = result.action;

    if (targetAction == null) {
      return MoveNotDone('No moves was made', null, move.from);
    }

    if (doMove) {
      _doMoveCards(
        result,
        doAfterMove: doAfterMove,
        isAutoMove: isAutoMove,
      );
    }
    return MoveSuccess(targetAction);
  }

  MoveResult tryQuickMove(PlayCard card, Pile from, {bool doMove = true}) {
    final game = ref.read(currentGameProvider);
    final table = ref.read(currentTableProvider);

    final args = MoveAttemptArgs(
      table: table,
      from: from,
      card: card,
      lastAction: ref.read(currentActionProvider),
      moveState: ref.read(currentMoveProvider)?.state,
    );

    for (final move in MoveAttemptTo.getAttempts(game.game.quickMove, args)) {
      final result = tryMove(move, doMove: doMove);
      if (result is MoveSuccess) {
        return result;
      }
    }

    return MoveNotDone('Cannot move this card anywhere', card, from);
  }

  Future<void> autoSolve() async {
    final game = ref.read(currentGameProvider);
    // TODO: Check for auto solve status

    bool handled, isWinning;

    ref.read(playTimeProvider.notifier).pause();
    state = GameStatus.autoSolving;

    do {
      handled = false;
      final table = ref.read(currentTableProvider);

      final args = MoveAttemptArgs(
        table: table,
        lastAction: ref.read(currentActionProvider),
        moveState: ref.read(currentMoveProvider)?.state,
      );

      for (final move in MoveAttempt.getAttempts(game.game.autoSolve, args)) {
        final result = tryMove(move, doAfterMove: false);
        if (result is MoveSuccess) {
          handled = true;
          await Future.delayed(autoMoveDelay * timeDilation);
          break;
        }
      }
      isWinning = ref.read(isGameFinishedProvider);
    } while (handled && !isWinning);

    if (!isWinning) {
      ref.read(playTimeProvider.notifier).resume();
    }
  }

  ScoreSummary getScoreSummary() {
    return ScoreSummary(
      playTime: ref.read(playTimeProvider),
      moves: ref.read(currentMoveNumberProvider) ?? 0,
      obtainedScore: ref.read(currentScoreProvider) ?? 0,
    );
  }

  // ----------------------------------

  PlayTable _setupPiles() {
    final gameData = ref.read(currentGameProvider);
    PlayTable table = PlayTable.fromGame(gameData.game);
    final moveState = ref.read(currentMoveProvider)?.state;

    for (final (pile, props) in gameData.game.setup.items) {
      final result = MoveAction.runAll(
        props.onStart,
        MoveActionArgs(
          pile: pile,
          table: table,
          metadata: gameData,
          moveState: moveState,
        ),
      );
      if (result is MoveActionHandled) {
        table = result.table;
      }
    }

    return table;
  }

  PlayTable _setupCards(PlayTable table) {
    final gameData = ref.read(currentGameProvider);
    final moveState = ref.read(currentMoveProvider)?.state;

    for (final (pile, props) in gameData.game.setup.items) {
      final result = MoveAction.runAll(
        props.onSetup,
        MoveActionArgs(
          pile: pile,
          table: table,
          metadata: gameData,
          moveState: moveState,
        ),
      );
      if (result is MoveActionHandled) {
        table = result.table;
      }
    }

    return table;
  }

  Duration _estimateDistributionAnimationTime(PlayTable table) {
    final minMaxTracker = MinMaxTracker<Duration>();
    const distributeAnimationDelay = CardDistributeAnimationDelay();

    for (final pile in table.allPiles()) {
      minMaxTracker
          .add(distributeAnimationDelay.compute(pile, table.get(pile).length));
    }
    return (minMaxTracker.max ?? Duration.zero) + cardMoveAnimation.duration;
  }

  Future<void> _doPostMove() async {
    final game = ref.read(currentGameProvider);

    ref.read(playTimeProvider.notifier).pause();

    bool handled, isWinning;
    do {
      await Future.delayed(autoMoveDelay * timeDilation);
      handled = false;
      final table = ref.read(currentTableProvider);

      final args = MoveAttemptArgs(
        table: table,
        lastAction: ref.read(currentActionProvider),
        moveState: ref.read(currentMoveProvider)?.state,
      );

      for (final move in MoveAttempt.getAttempts(game.game.postMove, args)) {
        final result = tryMove(
          move,
          doAfterMove: false,
          isAutoMove: true,
        );
        if (result is MoveSuccess) {
          handled = true;
          break;
        }
      }
      isWinning = ref.read(isGameFinishedProvider);
    } while (handled && !isWinning);

    if (!isWinning) {
      ref.read(playTimeProvider.notifier).resume();
    }
  }

  Future<void> _doPremove() async {
    final game = ref.read(currentGameProvider);

    final lastAction = ref.read(currentActionProvider);

    ref.read(playTimeProvider.notifier).pause();

    bool handled, isWinning;
    do {
      await Future.delayed(autoMoveDelay * timeDilation);
      handled = false;
      final table = ref.read(currentTableProvider);

      final args = MoveAttemptArgs(
        table: table,
        lastAction: ref.read(currentActionProvider),
        moveState: ref.read(currentMoveProvider)?.state,
      );
      for (final move in MoveAttempt.getAttempts(game.game.premove, args)) {
        // The card was just recently move. Skip that
        if (lastAction is Move &&
            lastAction.to == move.from &&
            lastAction.to is! Waste) {
          continue;
        }
        final result = tryMove(move, doAfterMove: false);
        if (result is MoveSuccess) {
          handled = true;
          break;
        }
      }
      isWinning = ref.read(isGameFinishedProvider);
    } while (handled && !isWinning);

    if (!isWinning) {
      ref.read(playTimeProvider.notifier).resume();
    }
  }

  void _doMoveCards(
    MoveActionResult result, {
    bool doAfterMove = true,
    bool isAutoMove = false,
  }) {
    if (result is! MoveActionHandled) {
      throw StateError('result is not handled');
    }

    final action = result.action;
    PlayTable updatedTable = result.table;

    // Clear any hinted cards if any
    ref.read(hintedCardsProvider.notifier).clear();

    // Detect if whole cards are just being relocated to another empty space
    final isEmptyPileMoveTransfer = action is Move &&
        action.from.runtimeType == action.to.runtimeType &&
        updatedTable.get(action.from).isEmpty &&
        updatedTable.get(action.to).length == action.cards.length;

    final score = _calculateScore(result.events);

    final recycledPiles = result.events
        .whereType<RecycleMade>()
        .map((e) => e.recycledPile)
        .toList();

    // Add to move records
    ref.read(moveHistoryProvider.notifier).add(
          updatedTable,
          action ?? const Idle(), // TODO: Check not null
          score: score,
          isAutoMove: isAutoMove,
          skipMoveCount: isEmptyPileMoveTransfer,
          recycledPiles: recycledPiles,
        );

    // Check if the game is winning
    if (ref.read(isGameFinishedProvider)) {
      state = GameStatus.finished;
      return;
    }

    if (state == GameStatus.started) {
      // Post moves will always be made, if available
      _doPostMove();

      // If possible and allowed to premove, do it
      if (doAfterMove && ref.read(settingsUseAutoPremoveProvider)) {
        _doPremove();
      }
    }
  }

  int _calculateScore(List<MoveEvent> events) {
    final game = ref.read(currentGameProvider);
    return events.fold(
        0, (prev, event) => prev + game.game.determineScore(event));
  }

  Iterable<(PlayCard card, Pile pile)> _getAllMovableCards() sync* {
    final table = ref.read(currentTableProvider);
    final game = ref.read(currentGameProvider);

    for (final (pile, props) in game.game.setup.items) {
      final canOnlyMoveTop = props.pickable.findRule<CardIsOnTop>() != null;
      final canOnlyTap = props.onTap != null;

      if (canOnlyTap) {
        continue;
      }
      final cardsOnPile = table.get(pile);
      if (cardsOnPile.isEmpty) {
        continue;
      }

      if (canOnlyMoveTop) {
        yield (cardsOnPile.last, pile);
      } else {
        for (final c in cardsOnPile) {
          if (c.isFacingUp) {
            yield (c, pile);
          }
        }
      }
    }
  }
}

@riverpod
bool isGameFinished(IsGameFinishedRef ref) {
  final game = ref.watch(currentGameProvider);
  final table = ref.watch(currentTableProvider);
  final moveState = ref.watch(currentMoveProvider)?.state;

  // TODO: Change "pile" parameter
  final result = MoveCheck.checkAll(
    game.game.objectives,
    MoveCheckArgs(
      pile: const Stock(0),
      cards: const PlayCardList.empty(),
      table: table,
      moveState: moveState,
    ),
  );
  return result is MoveCheckOK;
}

@riverpod
bool autoSolvable(AutoSolvableRef ref) {
  final game = ref.watch(currentGameProvider);
  final table = ref.watch(currentTableProvider);
  final moveState = ref.watch(currentMoveProvider)?.state;

  if (game.game.canAutoSolve == null) {
    return false;
  }

  // TODO: Change "pile" parameter
  final result = MoveCheck.checkAll(
    game.game.canAutoSolve,
    MoveCheckArgs(
      pile: const Stock(0),
      cards: const PlayCardList.empty(),
      table: table,
      moveState: moveState,
    ),
  );
  return result is MoveCheckOK;
}

@riverpod
class HintedCards extends _$HintedCards {
  static Timer? _highlightTimer;

  @override
  PlayCardList? build() {
    return null;
  }

  void clear() {
    state = null;
  }

  void highlight(PlayCardList cards) {
    _highlightTimer?.cancel();

    state = cards;
    _highlightTimer = Timer(const Duration(milliseconds: 1500), () {
      state = null;
    });
  }
}

@riverpod
class UserAction extends _$UserAction {
  @override
  UserActionOptions? build() => null;

  void set(UserActionOptions action) => state = action;

  void clear() => state = null;
}
