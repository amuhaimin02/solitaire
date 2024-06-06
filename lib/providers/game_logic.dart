import 'package:flutter/scheduler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../animations.dart';
import '../models/action.dart';
import '../models/card.dart';
import '../models/card_list.dart';
import '../models/game/klondike.dart';
import '../models/game/solitaire.dart';
import '../models/game_status.dart';
import '../models/move_record.dart';
import '../models/move_result.dart';
import '../models/pile.dart';
import '../models/pile_action.dart';
import '../models/pile_check.dart';
import '../models/play_data.dart';
import '../models/play_table.dart';
import '../models/user_action.dart';
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
    ref.read(moveHistoryProvider.notifier).add(setupTable, const GameStart());
    await Future.delayed(cardMoveAnimation.duration * timeDilation * 5);

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
    for (final (card, from) in _getAllVisibleCards()) {
      if (tryQuickMove(card, from, doMove: false) is MoveSuccess) {
        movableCards.add(card);
      }
    }
    if (movableCards.isEmpty) {
      final drawPile = table.drawPile;
      if (drawPile.isNotEmpty) {
        movableCards.add(drawPile.last);
      }
    }

    if (movableCards.isNotEmpty) {
      ref.read(hintedCardsProvider.notifier).highlight(movableCards);
      return true;
    } else {
      return false;
    }
  }

  MoveResult tryMove(
    MoveIntent move, {
    bool doMove = true,
    bool doAfterMove = true,
    bool retainMoveCount = false,
  }) {
    final game = ref.read(currentGameProvider);
    PlayTable table = ref.read(currentTableProvider);

    final originPileInfo = game.game.piles.get(move.from);

    final targetPileInfo = game.game.piles.get(move.to);

    final cardToMove = move.card;
    final cardsInPile = table.get(move.from);

    final List<PlayCard> cardsToPick;
    if (cardToMove != null) {
      cardsToPick = cardsInPile.getLastFromCard(cardToMove);
    } else {
      if (cardsInPile.isEmpty) {
        cardsToPick = [];
      } else {
        cardsToPick = [cardsInPile.last];
      }
    }

    PileActionResult result = PileActionNoChange(table: table);

    if (originPileInfo.onTap != null && move.from == move.to) {
      result = PileAction.run(
        originPileInfo.onTap,
        move.from,
        table,
        game,
      );
    } else {
      if (move.from == move.to) {
        return MoveForbidden('Cannot move cards back to its pile', move);
      }

      if (result is! PileActionHandled || result.action == null) {
        if (cardsToPick.isEmpty) {
          return MoveNotDone('No cards to pick', null, move.from);
        }

        final canPickResult = PileCheck.checkAll(
            originPileInfo.pickable, move.from, null, cardsToPick, table);
        if (canPickResult is PileCheckFail) {
          return MoveForbidden(
              'Cannot pick the card(s) from ${move.from}\n${canPickResult.reason.runtimeType}',
              move);
        }

        final canPlaceResult = PileCheck.checkAll(
            targetPileInfo.placeable, move.to, move.from, cardsToPick, table);

        if (canPlaceResult is PileCheckFail) {
          return MoveForbidden(
              'Cannot place the card(s) on ${move.to}\n${canPlaceResult.reason.runtimeType}',
              move);
        }

        result = PileAction.run(
          originPileInfo.makeMove?.call(move) ??
              [MoveNormally(to: move.to, cards: cardsToPick)],
          move.from,
          table,
          game,
        );
      }
    }
    for (final (pile, props) in game.game.piles.items) {
      if (props.afterMove != null) {
        result = PileAction.chain(
          result,
          props.afterMove,
          pile,
          game,
        );
      }
    }

    if (result is! PileActionHandled) {
      return MoveNotDone('Move result is not successful', null, move.from);
    }

    Action? targetAction = result.action;

    if (targetAction == null) {
      return MoveNotDone('No moves was made', null, move.from);
    }

    if (doMove) {
      _doMoveCards(result,
          doAfterMove: doAfterMove, retainMoveCount: retainMoveCount);
    }
    return MoveSuccess(targetAction);
  }

  MoveResult tryQuickMove(PlayCard card, Pile from, {bool doMove = true}) {
    final game = ref.read(currentGameProvider);
    final table = ref.read(currentTableProvider);

    for (final move in game.game.quickMoveStrategy(from, card, table)) {
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
      for (final move in game.game.autoSolveStrategy(table)) {
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

  // ----------------------------------

  PlayTable _setupPiles() {
    final gameData = ref.read(currentGameProvider);
    PlayTable table = PlayTable.fromGame(gameData.game);

    for (final (pile, props) in gameData.game.piles.items) {
      final result = PileAction.run(props.onStart, pile, table, gameData);
      if (result is PileActionHandled) {
        table = result.table;
      }
    }

    return table;
  }

  PlayTable _setupCards(PlayTable table) {
    final gameData = ref.read(currentGameProvider);

    for (final (pile, props) in gameData.game.piles.items) {
      final result = PileAction.run(props.onSetup, pile, table, gameData);
      if (result is PileActionHandled) {
        table = result.table;
      }
    }

    return table;
  }

  Future<void> _doPostMove() async {
    final game = ref.read(currentGameProvider);

    ref.read(playTimeProvider.notifier).pause();

    bool handled, isWinning;
    do {
      await Future.delayed(autoMoveDelay * timeDilation);
      handled = false;
      final table = ref.read(currentTableProvider);
      for (final move in game.game.postMoveStrategy(table)) {
        final result = tryMove(move, doAfterMove: false, retainMoveCount: true);
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
      for (final move in game.game.premoveStrategy(table)) {
        // The card was just recently move. Skip that
        if (lastAction is Move &&
            lastAction.to == move.from &&
            lastAction.to is! Discard) {
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
    PileActionResult result, {
    bool doAfterMove = true,
    bool retainMoveCount = false,
  }) {
    if (result is! PileActionHandled) {
      throw StateError('result is not handled');
    }

    final action = result.action;
    PlayTable updatedTable = result.table;

    // Clear any hinted cards if any
    ref.read(hintedCardsProvider.notifier).clear();

    // Add to move records
    ref.read(moveHistoryProvider.notifier).add(
          updatedTable,
          action ?? const Idle(),
          retainMoveCount: retainMoveCount,
        );

    // Check if the game is winning
    if (ref.read(isGameFinishedProvider)) {
      state = GameStatus.finished;
      return;
    }

    if (doAfterMove && state == GameStatus.started) {
      // Post moves will always be made, if available
      _doPostMove();

      // If possible and allowed to premove, do it
      if (ref.read(settingsUseAutoPremoveProvider)) {
        _doPremove();
      }
    }
  }

  Iterable<(PlayCard card, Pile pile)> _getAllVisibleCards() sync* {
    final table = ref.read(currentTableProvider);
    for (final t in table.allTableauPiles) {
      for (final c in table.get(t)) {
        yield (c, t);
      }
    }
    for (final f in table.allFoundationPiles) {
      if (table.get(f).isNotEmpty) {
        yield (table.get(f).last, f);
      }
    }

    if (table.discardPile.isNotEmpty) {
      yield (table.discardPile.last, const Discard());
    }
  }
}

@riverpod
bool isGameFinished(IsGameFinishedRef ref) {
  final game = ref.watch(currentGameProvider);
  final table = ref.watch(currentTableProvider);

  return game.game.winConditions(table);
}

@riverpod
bool autoSolvable(AutoSolvableRef ref) {
  final game = ref.watch(currentGameProvider);
  final table = ref.watch(currentTableProvider);

  return game.game.canAutoSolve(table);
}

@riverpod
class HintedCards extends _$HintedCards {
  @override
  List<PlayCard>? build() {
    return null;
  }

  void clear() {
    state = null;
  }

  void highlight(List<PlayCard> cards) {
    state = cards;
    Future.delayed(const Duration(seconds: 1), () {
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

// --------------------------------------
@riverpod
class GameDebug extends _$GameDebug {
  @override
  void build() {
    return;
  }

  void debugTestCustomLayout() {
    final game = ref.read(currentGameProvider);

    if (game.game is! Klondike) {
      return;
    }

    final presetCards = PlayTable.fromMap({
      const Draw(): [
        const PlayCard(Suit.club, Rank.four).faceDown(),
        const PlayCard(Suit.heart, Rank.four).faceDown(),
        const PlayCard(Suit.spade, Rank.four).faceDown(),
        const PlayCard(Suit.heart, Rank.five).faceDown(),
        const PlayCard(Suit.club, Rank.five).faceDown(),
        const PlayCard(Suit.club, Rank.six).faceDown(),
        const PlayCard(Suit.club, Rank.two).faceDown(),
      ],
      const Discard(): const [],
      const Foundation(0): const [PlayCard(Suit.heart, Rank.ace)],
      const Foundation(1): const [PlayCard(Suit.diamond, Rank.ace)],
      const Foundation(2): const [PlayCard(Suit.club, Rank.ace)],
      const Foundation(3): const [PlayCard(Suit.spade, Rank.ace)],
      const Tableau(0): const [
        PlayCard(Suit.heart, Rank.three),
        PlayCard(Suit.heart, Rank.two)
      ],
      const Tableau(1): const [
        PlayCard(Suit.spade, Rank.three),
        PlayCard(Suit.spade, Rank.two),
      ],
      const Tableau(2): const [
        PlayCard(Suit.diamond, Rank.three),
        PlayCard(Suit.diamond, Rank.two),
      ],
      const Tableau(3): const [PlayCard(Suit.club, Rank.three)],
    });

    ref.read(moveHistoryProvider.notifier).add(presetCards, const GameStart());
  }
}
