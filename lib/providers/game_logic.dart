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
import '../models/play_data.dart';
import '../models/play_table.dart';
import '../models/user_action.dart';
import '../utils/iterators.dart';
import '../utils/prng.dart';
import '../utils/stopwatch.dart';
import 'game_selection.dart';
import 'settings.dart';

part 'game_logic.g.dart';

@riverpod
class Score extends _$Score {
  @override
  int build() {
    return 0;
  }

  void set(int value) => state = value;

  void reset() => state = 0;

  void add(int value) {
    state += value;
  }
}

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
class MoveCount extends _$MoveCount {
  @override
  int build() {
    return 0;
  }

  void set(int value) => state = value;

  void reset() => state = 0;

  void forward() => state++;

  void reverse() => state--;
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
class PlayTableState extends _$PlayTableState {
  @override
  PlayTable build() => PlayTable.empty();

  void update(PlayTable table) {
    state = table;
  }
}

@riverpod
class GameController extends _$GameController {
  @override
  GameStatus build() => GameStatus.ready;

  Future<void> startNew(SolitaireGame game) async {
    // Prepare a new game to start
    final newPlayData = GameMetadata(
      game: game,
      startedTime: DateTime.now(),
      randomSeed: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    ref.read(lastActionProvider.notifier).send(const Idle());
    ref.read(currentGameProvider.notifier).start(newPlayData);
    ref.read(moveCountProvider.notifier).reset();
    ref.read(scoreProvider.notifier).reset();

    // Setup draw piles for the new game
    _setupPiles();
    state = GameStatus.initializing;
    await Future.delayed(cardMoveAnimation.duration * timeDilation * 2);

    // Start distribute cards according to game
    _setupCards();
    state = GameStatus.preparing;
    await Future.delayed(cardMoveAnimation.duration * timeDilation * 5);

    ref.read(playTimeProvider.notifier).restart();
    ref.read(moveHistoryProvider.notifier).createNew();
    state = GameStatus.started;

    if (ref.read(settingsUseAutoPremoveProvider)) {
      _doPremove();
    }
  }

  void restart() async {
    ref.read(moveHistoryProvider.notifier).restart();
    ref.read(playTimeProvider.notifier).restart();
    ref.read(scoreProvider.notifier).reset();
  }

  GameData suspend() {
    // Stop timer to release resources
    ref.read(playTimeProvider.notifier).pause();

    return GameData(
      metadata: ref.read(currentGameProvider),
      state: GameState(
        moves: ref.read(moveCountProvider),
        score: ref.read(scoreProvider),
        playTime: ref.read(playTimeProvider),
      ),
      history: ref.read(moveHistoryProvider),
    );
  }

  void restore(GameData gameData) {
    ref.read(lastActionProvider.notifier).send(const Idle());
    ref.read(currentGameProvider.notifier).start(gameData.metadata);
    ref.read(scoreProvider.notifier).set(gameData.state.score);
    ref.read(moveCountProvider.notifier).set(gameData.state.moves);
    ref.read(playTimeProvider.notifier).set(gameData.state.playTime);
    ref.read(moveHistoryProvider.notifier).set(gameData.history);
    ref
        .read(playTableStateProvider.notifier)
        .update(gameData.history[gameData.state.moves].table);

    // Start timer immediately
    ref.read(playTimeProvider.notifier).resume();

    state = GameStatus.started;
  }

  void highlightHints() {
    final table = ref.read(playTableStateProvider);

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

    ref.read(hintedCardsProvider.notifier).highlight(movableCards);
  }

  MoveResult tryMove(MoveIntent move,
      {bool doMove = true, bool doPreMove = true}) {
    final game = ref.read(currentGameProvider);
    final table = ref.read(playTableStateProvider);

    final Move? targetMove;

    Move refreshDrawPile() {
      // Try to refresh draw pile
      return Move(
        table.discardPile.reversed.toList().allFaceDown,
        const Discard(),
        const Draw(),
      );
    }

    switch (move.from) {
      case Draw():
        if (move.to != const Discard()) {
          return MoveForbidden(
              'cannot move cards from draw pile to pile other than discard',
              move);
        }
        final cardsInDrawPile = table.drawPile;

        if (cardsInDrawPile.isEmpty) {
          // Try to refresh draw pile
          final cardsInDiscardPile = table.discardPile;

          if (cardsInDiscardPile.isEmpty) {
            return MoveNotDone('No cards to refresh', null, move.from);
          }

          targetMove = refreshDrawPile();
        } else {
          // Pick from draw pile
          final cardsToPick = cardsInDrawPile.getLast(game.game.drawsPerTurn);
          targetMove = Move(
            [...cardsToPick.allFaceUp],
            const Draw(),
            const Discard(),
          );
        }
      case Discard() || Foundation() || Tableau():
        if (move.from == move.to) {
          return MoveForbidden('cannot move cards back to its pile', move);
        }

        if (move.to == const Draw()) {
          if (table.drawPile.isEmpty) {
            targetMove = refreshDrawPile();
          } else {
            return MoveForbidden('cannot move cards back to draw pile', move);
          }
        } else {
          final cardToMove = move.card;
          final cardsInPile = table.get(move.from);

          final List<PlayCard> cardsToPick;

          if (move.from is! Tableau &&
              move.card != null &&
              cardsInPile.isNotEmpty &&
              move.card != cardsInPile.last) {
            return MoveForbidden('can only move card on top of pile', move);
          }

          if (cardToMove != null) {
            cardsToPick = cardsInPile.getLastFromCard(cardToMove);
          } else {
            if (cardsInPile.isEmpty) {
              return MoveNotDone('No cards in pile', null, move.from);
            }
            cardsToPick = [cardsInPile.last];
          }

          if (!game.game.canPick(cardsToPick, move.from)) {
            return MoveForbidden(
                'cannot pick the card(s) $cardsToPick from ${move.from}', move);
          }
          if (!game.game.canPlace(cardsToPick, move.to, table.get(move.to))) {
            return MoveForbidden(
                'cannot place the card(s) $cardsToPick on ${move.to}', move);
          }

          targetMove = Move(cardsToPick, move.from, move.to);
        }
    }

    if (doMove) {
      _doMoveCards(targetMove, doPremove: doPreMove);
    }

    return MoveSuccess(targetMove);
  }

  MoveResult tryQuickMove(PlayCard card, Pile from, {bool doMove = true}) {
    final foundationIndexes = RollingIndexIterator(
      count: 4,
      start: 0,
      direction: 1,
    );

    final tableauIndexes = RollingIndexIterator(
      count: 7,
      start: from is Tableau ? from.index : 0,
      direction: 1,
      startInclusive: from is! Tableau,
    );

    // Try placing on foundation pile first
    // For cards from foundation, no need to move to other foundations
    if (from is! Foundation) {
      for (final i in foundationIndexes) {
        final result =
            tryMove(MoveIntent(from, Foundation(i), card), doMove: doMove);
        if (result is MoveSuccess) {
          return result;
        }
      }
    }

    // Try placing on tableau next
    for (final i in tableauIndexes) {
      final result =
          tryMove(MoveIntent(from, Tableau(i), card), doMove: doMove);
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
      final table = ref.read(playTableStateProvider);
      for (final move in game.game.autoSolveStrategy(table)) {
        final result = tryMove(move, doPreMove: false);
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

  void _setupPiles() {
    final gameData = ref.read(currentGameProvider);
    PlayTable table = PlayTable.fromGame(gameData.game);

    for (final pile in gameData.game.piles) {
      if (pile.onStart != null) {
        table = PileAction.runAll(
          originTable: table,
          actions: pile.onStart!,
          pile: pile.kind,
          metadata: gameData,
        );
      }
    }

    ref.read(playTableStateProvider.notifier).update(table);
  }

  void _setupCards() {
    final gameData = ref.read(currentGameProvider);
    PlayTable table = ref.read(playTableStateProvider);

    for (final pile in gameData.game.piles) {
      if (pile.onSetup != null) {
        table = PileAction.runAll(
          originTable: table,
          actions: pile.onSetup!,
          pile: pile.kind,
          metadata: gameData,
        );
      }
    }

    ref.read(playTableStateProvider.notifier).update(table);
  }

  Future<void> _doPremove() async {
    final game = ref.read(currentGameProvider);

    final Action lastAction = ref.read(lastActionProvider);

    ref.read(playTimeProvider.notifier).pause();

    bool handled, isWinning;
    do {
      await Future.delayed(autoMoveDelay * timeDilation);
      handled = false;
      final table = ref.read(playTableStateProvider);
      for (final move in game.game.autoMoveStrategy(table)) {
        // The card was just recently move. Skip that
        if (lastAction is Move &&
            lastAction.to == move.from &&
            lastAction.to is! Discard) {
          continue;
        }
        final result = tryMove(move, doPreMove: false);
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

  Move _doMoveCards(Move move, {bool doPremove = true}) {
    final game = ref.read(currentGameProvider);
    final table = ref.read(playTableStateProvider);

    final cardsInHand = move.cards;
    final cardsOnTable = table.get(move.from);

    // Check and remove cards from source pile to hand
    final (remainingCards, cardsToPickUp) =
        cardsOnTable.splitLast(cardsInHand.length);

    // Check whether card picked is similar to what is on hand
    // if (!const ListEquality().equals(cardsToPickUp, cardsInHand)) {
    //   throw StateError("Cards picked up and in hand is not the same");
    // }

    // Move all cards on hand to target pile
    PlayTable updatedTable = table.modifyMultiple({
      move.from: remainingCards,
      move.to: [...table.get(move.to), ...cardsInHand]
    });

    // Clear any hinted cards if any
    ref.read(hintedCardsProvider.notifier).clear();

    final int score;
    (updatedTable, score) = game.game.afterEachMove(move, updatedTable);

    // Update cards on table with new version
    ref.read(playTableStateProvider.notifier).update(updatedTable);

    // Add in the new score for the move, if any
    ref.read(scoreProvider.notifier).add(score);

    // Add to move history
    ref.read(moveHistoryProvider.notifier).add(move);

    // Check if the game is winning
    if (ref.read(isGameFinishedProvider)) {
      state = GameStatus.finished;
    }

    // If possible and allowed to premove, do it
    if (doPremove &&
        ref.read(settingsUseAutoPremoveProvider) &&
        state == GameStatus.started) {
      _doPremove();
    }
    return move;
  }

  Iterable<(PlayCard card, Pile pile)> _getAllVisibleCards() sync* {
    final table = ref.read(playTableStateProvider);
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
class MoveHistory extends _$MoveHistory {
  @override
  List<MoveRecord> build() {
    return [];
  }

  void createNew() {
    final table = ref.read(playTableStateProvider);
    ref.read(lastActionProvider.notifier).send(const GameStart());
    state = [
      MoveRecord(action: const GameStart(), table: table),
    ];
  }

  void set(List<MoveRecord> records) => state = records;

  void add(Move move) {
    final table = ref.read(playTableStateProvider);
    final moves = ref.read(moveCountProvider);
    ref.read(moveCountProvider.notifier).forward();
    ref.read(lastActionProvider.notifier).send(move);
    state = [
      ...state.getRange(0, moves + 1),
      MoveRecord(action: move, table: table),
    ];
  }

  bool canUndo() {
    final moves = ref.read(moveCountProvider);
    return moves > 0;
  }

  bool canRedo() {
    final moves = ref.read(moveCountProvider);
    return moves < state.length - 1;
  }

  void undo() {
    final moves = ref.read(moveCountProvider.notifier);

    if (canUndo()) {
      final currentMove = state[moves.state].action as Move;
      ref.read(lastActionProvider.notifier).send(Undo(currentMove));
      moves.reverse();
      final record = state[moves.state];
      ref.read(playTableStateProvider.notifier).update(record.table);
    }
  }

  void redo() {
    final moves = ref.read(moveCountProvider.notifier);

    if (canRedo()) {
      moves.forward();
      final record = state[moves.state];
      ref.read(lastActionProvider.notifier).send(Undo(record.action as Move));
      ref.read(playTableStateProvider.notifier).update(record.table);
    }
  }

  void restart() {
    ref.read(moveCountProvider.notifier).set(0);
    ref.read(playTableStateProvider.notifier).update(state.first.table);
    ref.read(lastActionProvider.notifier).send(const GameStart());
    state = [state.first];
  }
}

@riverpod
class LastAction extends _$LastAction {
  @override
  Action build() => const Idle();

  void send(Action newAction) {
    state = newAction;
  }
}

// @riverpod
// Move? lastMove(LastMoveRef ref) {
//   final history = ref.watch(moveHistoryProvider);
//   final move = ref.watch(moveCountProvider);
//
//   if (history.isEmpty || move >= history.length) {
//     return null;
//   }
//   final lastAction = history[move].action;
//   return lastAction.move;
// }

@riverpod
bool isGameFinished(IsGameFinishedRef ref) {
  final game = ref.watch(currentGameProvider);
  final table = ref.watch(playTableStateProvider);

  return game.game.winConditions(table);
}

@riverpod
bool autoSolvable(AutoSolvableRef ref) {
  final game = ref.watch(currentGameProvider);
  final table = ref.watch(playTableStateProvider);

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

    ref.read(playTableStateProvider.notifier).update(presetCards);
  }
}
