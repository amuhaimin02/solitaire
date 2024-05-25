import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../animations.dart';
import '../models/card.dart';
import '../models/pile.dart';
import '../models/rules/klondike.dart';
import '../models/rules/rules.dart';
import '../models/rules/simple.dart';
import '../models/states/game.dart';
import '../utils/iterators.dart';
import '../utils/prng.dart';

part 'game_logic.g.dart';

@riverpod
class Score extends _$Score {
  @override
  int build() {
    ref.listen(currentGameProvider, (oldGame, newGame) {
      if (oldGame != newGame) {
        state = 0;
      }
    });
    return 0;
  }

  void add(int value) {
    state += value;
  }
}

@riverpod
class PlayTime extends _$PlayTime {
  static final _stopwatch = Stopwatch();

  @override
  Duration build() {
    return _stopwatch.elapsed;
  }

  void restart() {
    _stopwatch
      ..reset()
      ..start();
    ref.invalidateSelf();
  }

  void resume() {
    _stopwatch.start();
    ref.invalidateSelf();
  }

  void pause() {
    _stopwatch.stop();
    ref.invalidateSelf();
  }

  void stop() {
    _stopwatch
      ..stop()
      ..reset();
    ref.invalidateSelf();
  }
}

@riverpod
class Moves extends _$Moves {
  @override
  int build() {
    ref.listen(currentGameProvider, (oldGame, newGame) {
      if (oldGame != newGame) {
        state = 0;
      }
    });
    return 0;
  }

  void forward() => state++;

  void reverse() => state--;
}

@riverpod
class CurrentGame extends _$CurrentGame {
  // TODO: Make nullable
  @override
  PlayData build() {
    return PlayData(
      rules: SimpleSolitaire(),
      startedTime: DateTime.now(),
      randomSeed: "1234",
    );
  }

  void start(PlayData game) {
    print('start game ${game}');
    state = game;
  }
}

@riverpod
class CardsOnTable extends _$CardsOnTable {
  @override
  PlayCards build() => const PlayCards({});

  void update(PlayCards cards) {
    // TODO: Make playcards immutable
    state = cards.copy();
  }
}

@riverpod
class GameController extends _$GameController {
  @override
  GameStatus build() => GameStatus.ready;

  Future<void> startNew(SolitaireGame game) async {
    // Prepare a new game to start
    final newPlayData = PlayData(
      rules: game,
      startedTime: DateTime.now(),
      randomSeed: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    ref.read(currentGameProvider.notifier).start(newPlayData);

    // Setup draw piles for the new game
    _setupPiles();
    state = GameStatus.initializing;
    await Future.delayed(cardMoveAnimation.duration * timeDilation * 2);

    // Start distribute cards according to game
    _distributeCards();
    state = GameStatus.preparing;
    await Future.delayed(cardMoveAnimation.duration * timeDilation * 5);

    ref.read(playTimeProvider.notifier).restart();
    ref.read(moveHistoryProvider.notifier).createNew();
    state = GameStatus.started;

    // TODO: Read from settings
    _doPremove();
  }

  void highlightHints() {
    final cards = ref.read(cardsOnTableProvider);

    final movableCards = <PlayCard>[];
    for (final (card, from) in _getAllVisibleCards()) {
      if (tryQuickMove(card, from, doMove: false) is MoveSuccess) {
        movableCards.add(card);
      }
    }
    if (movableCards.isEmpty) {
      final drawPile = cards(const Draw());
      if (drawPile.isNotEmpty) {
        movableCards.add(drawPile.last);
      }
    }

    ref.read(hintedCardsProvider.notifier).highlight(movableCards);
  }

  MoveResult tryMove(MoveIntent move,
      {bool doMove = true, bool doPreMove = true}) {
    final game = ref.read(currentGameProvider);
    final cards = ref.read(cardsOnTableProvider);

    final Move? targetMove;

    Move refreshDrawPile() {
      // Try to refresh draw pile
      final cardsInDiscardPile = cards(const Discard());

      return Move(
        cardsInDiscardPile.reversed.toList().allFaceDown,
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
        final cardsInDrawPile = cards(const Draw());

        if (cardsInDrawPile.isEmpty) {
          // Try to refresh draw pile
          final cardsInDiscardPile = cards(const Discard());

          if (cardsInDiscardPile.isEmpty) {
            return MoveNotDone("No cards to refresh", null, move.from);
          }

          targetMove = refreshDrawPile();
        } else {
          // Pick from draw pile
          final cardsToPick = cardsInDrawPile.getLast(game.rules.drawsPerTurn);
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
          if (cards(const Draw()).isEmpty) {
            targetMove = refreshDrawPile();
          } else {
            return MoveForbidden('cannot move cards back to draw pile', move);
          }
        } else {
          final cardToMove = move.card;
          final cardsInPile = cards(move.from);

          final PlayCardList cardsToPick;

          if (move.from is! Tableau &&
              move.card != null &&
              cardsInPile.isNotEmpty &&
              move.card != cardsInPile.last) {
            return MoveForbidden('can only move card on top of pile', move);
          }

          if (cardToMove != null) {
            cardsToPick = cardsInPile.getUntilLast(cardToMove);
          } else {
            if (cardsInPile.isEmpty) {
              return MoveNotDone("No cards in pile", null, move.from);
            }
            cardsToPick = [cardsInPile.last];
          }

          if (!game.rules.canPick(cardsToPick, move.from)) {
            return MoveForbidden(
                'cannot pick the card(s) $cardsToPick from ${move.from}', move);
          }
          if (!game.rules.canPlace(cardsToPick, move.to, cards(move.to))) {
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

    return MoveNotDone("Cannot move this card anywhere", card, from);
  }

  Future<void> autoSolve() async {
    final game = ref.read(currentGameProvider);
    // TODO: Check for auto solve status

    bool handled, isWinning;

    ref.read(playTimeProvider.notifier).pause();
    state = GameStatus.autoSolving;

    do {
      handled = false;
      final cards = ref.read(cardsOnTableProvider);
      for (final move in game.rules.autoSolveStrategy(cards)) {
        final result = tryMove(move, doPreMove: false);
        if (result is MoveSuccess) {
          HapticFeedback.mediumImpact();
          handled = true;
          await Future.delayed(autoMoveDelay * timeDilation);
          break;
        }
      }
      isWinning = ref.read(isFinishedProvider);
    } while (handled && !isWinning);

    if (!isWinning) {
      ref.read(playTimeProvider.notifier).resume();
    }
  }

  // ----------------------------------

  void _setupPiles() {
    final game = ref.read(currentGameProvider);
    // Clear up tables, and set up new draw pile

    final cards = PlayCards.fromGame(game.rules);
    cards(const Draw()).addAll(game.rules
        .prepareDrawPile(CustomPRNG.create(game.randomSeed))
        .allFaceDown);

    ref.read(cardsOnTableProvider.notifier).update(cards);
  }

  void _distributeCards() {
    final cards = ref.read(cardsOnTableProvider);
    final game = ref.read(currentGameProvider);
    game.rules.setup(cards);

    ref.read(cardsOnTableProvider.notifier).update(cards);
  }

  Future<void> _doPremove() async {
    final game = ref.read(currentGameProvider);

    // TODO: Check for last move
    // final Move? lastMove = latestAction is Move ? (latestAction as Move) : null;

    ref.read(playTimeProvider.notifier).pause();

    bool handled, isWinning;
    do {
      await Future.delayed(autoMoveDelay * timeDilation);
      handled = false;
      final cards = ref.read(cardsOnTableProvider);
      for (final move in game.rules.autoMoveStrategy(cards)) {
        // The card was just recently move. Skip that
        // if (lastMove?.to == move.from && lastMove?.to is! Discard) {
        //   continue;
        // }
        final result = tryMove(move, doPreMove: false);
        if (result is MoveSuccess) {
          HapticFeedback.mediumImpact();
          handled = true;
          break;
        }
      }
      isWinning = ref.read(isFinishedProvider);
    } while (handled && !isWinning);

    if (!isWinning) {
      ref.read(playTimeProvider.notifier).resume();
    }
  }

  Move _doMoveCards(Move move, {bool doPremove = true}) {
    final game = ref.read(currentGameProvider);
    final cards = ref.read(cardsOnTableProvider);
    final cardsInHand = move.cards;

    final cardsOnTable = cards(move.from);

    // Check and remove cards from source pile to hand
    cardsOnTable.removeRange(
        cardsOnTable.length - cardsInHand.length, cardsOnTable.length);

    // Move all cards on hand to target pile
    cards(move.to).addAll(cardsInHand);

    // Clear any hinted cards if any
    ref.read(hintedCardsProvider.notifier).clear();

    final (newCards, score) = game.rules.afterEachMove(move, cards);

    // Update cards on table with new version
    ref.read(cardsOnTableProvider.notifier).update(newCards);

    // Add in the new score for the move, if any
    ref.read(scoreProvider.notifier).add(score);

    // Add to move history
    ref.read(moveHistoryProvider.notifier).add(move);

    // Check if the game is winning
    if (ref.read(isFinishedProvider)) {
      state = GameStatus.finished;
    }

    if (doPremove && state != GameStatus.autoSolving) {
      _doPremove();
    }
    return move;
  }

  Iterable<(PlayCard card, Pile pile)> _getAllVisibleCards() sync* {
    final game = ref.read(currentGameProvider);
    final cards = ref.read(cardsOnTableProvider);
    for (final t in game.rules.allTableaus) {
      for (final c in cards(t)) {
        yield (c, t);
      }
    }
    for (final f in game.rules.allFoundations) {
      if (cards(f).isNotEmpty) {
        yield (cards(f).last, f);
      }
    }

    if (cards(const Discard()).isNotEmpty) {
      yield (cards(const Discard()).last, const Discard());
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
    final cards = ref.read(cardsOnTableProvider);

    state = [
      MoveRecord(cards.copy(), GameStart()),
    ];
  }

  void add(Move move) {
    final cards = ref.read(cardsOnTableProvider);
    ref.read(movesProvider.notifier).forward();

    state = [
      ...state,
      MoveRecord(cards.copy(), move),
    ];
  }

  bool get canUndo {
    final moves = ref.read(movesProvider);
    return moves > 0;
  }

  bool get canRedo {
    final moves = ref.read(movesProvider);
    return moves < state.length - 1;
  }

  void undo() {
    final moves = ref.read(movesProvider.notifier);

    if (canUndo) {
      moves.reverse();
      final record = state[moves.state];
      ref.read(cardsOnTableProvider.notifier).update(record.cards);
    }
  }

  void redo() {
    final moves = ref.read(movesProvider.notifier);

    if (canRedo) {
      moves.forward();
      final record = state[moves.state];
      ref.read(cardsOnTableProvider.notifier).update(record.cards);
    }
  }
}

// @riverpod
// Move lastMove(LastMoveRef ref) {
//   return null;
// }

@riverpod
bool isFinished(IsFinishedRef ref) {
  final game = ref.watch(currentGameProvider);
  final cards = ref.watch(cardsOnTableProvider);

  return game.rules.winConditions(cards);
}

@riverpod
bool autoSolvable(AutoSolvableRef ref) {
  final game = ref.watch(currentGameProvider);
  final cards = ref.watch(cardsOnTableProvider);

  return game.rules.canAutoSolve(cards);
}

@riverpod
class HintedCards extends _$HintedCards {
  @override
  PlayCardList? build() {
    return null;
  }

  void clear() {
    state = null;
  }

  void highlight(PlayCardList cards) {
    state = cards;
    Future.delayed(const Duration(seconds: 1), () {
      state = null;
    });
  }
}

@riverpod
UserAction? userAction(UserActionRef ref) {
  return null;
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

    if (game.rules is! Klondike) {
      return;
    }

    final presetCards = PlayCards({
      const Draw(): [
        const PlayCard(Suit.club, Rank.four).faceDown(),
        const PlayCard(Suit.heart, Rank.four).faceDown(),
        const PlayCard(Suit.spade, Rank.four).faceDown(),
        const PlayCard(Suit.heart, Rank.five).faceDown(),
        const PlayCard(Suit.club, Rank.five).faceDown(),
        const PlayCard(Suit.club, Rank.six).faceDown(),
        const PlayCard(Suit.club, Rank.two).faceDown(),
      ],
      const Discard(): [],
      const Foundation(0): [const PlayCard(Suit.heart, Rank.ace)],
      const Foundation(1): [const PlayCard(Suit.diamond, Rank.ace)],
      const Foundation(2): [const PlayCard(Suit.club, Rank.ace)],
      const Foundation(3): [const PlayCard(Suit.spade, Rank.ace)],
      const Tableau(0): [
        const PlayCard(Suit.heart, Rank.three),
        const PlayCard(Suit.heart, Rank.two)
      ],
      const Tableau(1): [
        const PlayCard(Suit.spade, Rank.three),
        const PlayCard(Suit.spade, Rank.two),
      ],
      const Tableau(2): [
        const PlayCard(Suit.diamond, Rank.three),
        const PlayCard(Suit.diamond, Rank.two),
      ],
      const Tableau(3): [const PlayCard(Suit.club, Rank.three)],
    });

    ref.read(cardsOnTableProvider.notifier).update(presetCards);
  }
}