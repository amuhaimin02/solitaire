import 'package:flutter/material.dart' hide Action;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../animations.dart';
import '../utils/iterators.dart';
import '../utils/prng.dart';
import 'card.dart';
import 'pile.dart';
import 'rules/klondike.dart';
import 'rules/rules.dart';
import 'score_tracker.dart';

enum GameStatus {
  initiializing,
  ready,
  preparing,
  started,
  autoSolving,
  ended,
  restarting
}

enum UserAction { undoMultiple, redoMultiple }

class GameState extends ChangeNotifier {
  late String _gameSeed;

  late SolitaireRules rules = Klondike();

  late GameStatus _status;

  late List<GameHistory> _history;

  late int _currentMoveIndex;

  late int _reshuffleCount;

  late ScoreTracker _score;

  late int _undoCount;

  late bool _isUndoing;

  late bool _canAutoSolve;

  PlayCardList? _hintedCards;

  late PlayCards _cards;

  AutoMoveLevel _autoMoveLevel = AutoMoveLevel.off;

  final _stopWatch = Stopwatch();

  GameState() {
    _resetStates();
    _setupPiles();
    _distributeCards();
    _status = GameStatus.initiializing;
  }

  bool get isWinning => _status == GameStatus.ended;

  AutoMoveLevel get autoMoveLevel => _autoMoveLevel;

  set autoMoveLevel(AutoMoveLevel value) {
    _autoMoveLevel = value;
  }

  String get gameSeed => _gameSeed;

  int get moves => _currentMoveIndex;

  int get historyCount => _history.length;

  Duration get playTime => _stopWatch.elapsed;

  int get score => _score.value;

  int get reshuffleCount => _reshuffleCount;

  int get undoCount => _undoCount;

  bool get isUndoing => _isUndoing;

  GameStatus get status => _status;

  bool get isPreparing => [
        GameStatus.initiializing,
        GameStatus.ready,
        GameStatus.preparing,
        GameStatus.restarting,
      ].contains(status);

  bool get canAutoSolve => _canAutoSolve;

  PlayCardList? get hintedCards => _hintedCards;

  Action? get latestAction {
    if (_isUndoing && _currentMoveIndex < _history.length - 1) {
      return _history[_currentMoveIndex + 1].action;
    } else {
      if (_currentMoveIndex == 0) {
        return null;
      }
      return _history[_currentMoveIndex].action;
    }
  }

  UserAction? _userAction;

  UserAction? get userAction => _userAction;

  set userAction(UserAction? action) {
    _userAction = action;
    notifyListeners();
  }

  bool get isJustStarting => _history.length == 1;

  Future<void> startNewGame({bool keepSeed = false}) async {
    if (!keepSeed) {
      _gameSeed = CustomPRNG.generateSeed(length: 12);
    }
    if (_status == GameStatus.initiializing) {
      _status = GameStatus.ready;
    } else {
      _status = GameStatus.restarting;
    }
    _resetStates();

    _stopWatch
      ..stop()
      ..reset();
    _setupPiles();
    notifyListeners();

    await Future.delayed(cardMoveAnimation.duration * timeDilation * 2);
    _status = GameStatus.preparing;
    _distributeCards();
    _updateHistory(GameStart());
    notifyListeners();

    await Future.delayed(cardMoveAnimation.duration * timeDilation * 5);

    _status = GameStatus.started;
    _stopWatch.start();

    notifyListeners();

    if (_autoMoveLevel != AutoMoveLevel.off) {
      _doAutoMove();
    }
  }

  Future<void> testCustomLayout() async {
    _resetStates();
    _setupPiles();

    _updateHistory(GameStart());

    _cards = PlayCards({
      const Draw(): [
        const PlayCard(Suit.club, Value.four).faceDown(),
        const PlayCard(Suit.heart, Value.four).faceDown(),
        const PlayCard(Suit.spade, Value.four).faceDown(),
        const PlayCard(Suit.heart, Value.five).faceDown(),
        const PlayCard(Suit.club, Value.five).faceDown(),
        const PlayCard(Suit.club, Value.six).faceDown(),
        const PlayCard(Suit.club, Value.two).faceDown(),
      ],
      const Discard(): [],
      const Foundation(0): [const PlayCard(Suit.heart, Value.ace)],
      const Foundation(1): [const PlayCard(Suit.diamond, Value.ace)],
      const Foundation(2): [const PlayCard(Suit.club, Value.ace)],
      const Foundation(3): [const PlayCard(Suit.spade, Value.ace)],
      const Tableau(0): [
        const PlayCard(Suit.heart, Value.three),
        const PlayCard(Suit.heart, Value.two)
      ],
      const Tableau(1): [
        const PlayCard(Suit.spade, Value.three),
        const PlayCard(Suit.spade, Value.two),
      ],
      const Tableau(2): [
        const PlayCard(Suit.diamond, Value.three),
        const PlayCard(Suit.diamond, Value.two),
      ],
      const Tableau(3): [const PlayCard(Suit.club, Value.three)],
    });

    notifyListeners();
  }

  void restartGame() {
    startNewGame(keepSeed: true);
  }

  void _resetStates() {
    _history = [];
    _currentMoveIndex = 0;
    _reshuffleCount = 0;
    _undoCount = 0;
    _score = ScoreTracker();
    _isUndoing = false;
    _canAutoSolve = false;
    _gameSeed = CustomPRNG.generateSeed(length: 12);
  }

  void _setupPiles() {
    // Clear up tables, and set up new draw pile
    _cards = PlayCards({
      const Draw():
          rules.prepareDrawPile(CustomPRNG.create(_gameSeed)).allFaceDown,
      const Discard(): [],
      for (int i = 0; i < rules.numberOfFoundationPiles; i++) Foundation(i): [],
      for (int i = 0; i < rules.numberOfTableauPiles; i++) Tableau(i): [],
    });
  }

  void _distributeCards() {
    rules.setup(_cards);
  }

  void testDistributeToOtherPiles() {
    for (int i = 0; i < rules.numberOfFoundationPiles; i++) {
      for (int j = 0; i < j; j++) {
        _cards(Foundation(i)).add(_cards(const Draw()).removeLast().faceUp());
      }
    }
    for (int i = 0; i < 7; i++) {
      _cards(const Discard()).add(_cards(const Draw()).removeLast().faceUp());
    }
  }

  PlayCards get cardsOnTable => _cards;

  Move _doMoveCards(Move move) {
    try {
      final cardsInHand = move.cards;

      final cardsOnTable = _cards(move.from);

      // Check and remove cards from source pile to hand
      cardsOnTable.removeRange(
          cardsOnTable.length - cardsInHand.length, cardsOnTable.length);

      // Move all cards on hand to target pile
      _cards(move.to).addAll(cardsInHand);

      _hintedCards = null;

      rules.afterEachMove(move, _cards, _score);

      _postCheckAfterPlacement();

      _updateHistory(move);

      _isUndoing = false;

      if (_status != GameStatus.autoSolving &&
          _autoMoveLevel != AutoMoveLevel.off) {
        _doAutoMove();
      }
    } catch (e) {
      rethrow;
    } finally {
      notifyListeners();
    }
    return move;
  }

  MoveResult tryMove(MoveIntent move, {bool doMove = true}) {
    final Move? targetMove;

    Move refreshDrawPile() {
      // Try to refresh draw pile
      final cardsInDiscardPile = _cards(const Discard());

      _reshuffleCount++;

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
        final cardsInDrawPile = _cards(const Draw());

        if (cardsInDrawPile.isEmpty) {
          // Try to refresh draw pile
          final cardsInDiscardPile = _cards(const Discard());

          if (cardsInDiscardPile.isEmpty) {
            return MoveNotDone("No cards to refresh", null, move.from);
          }

          targetMove = refreshDrawPile();
        } else {
          // Pick from draw pile
          final cardsToPick = cardsInDrawPile.getLast(rules.drawsPerTurn);
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
          if (_cards(const Draw()).isEmpty) {
            targetMove = refreshDrawPile();
          } else {
            return MoveForbidden('cannot move cards back to draw pile', move);
          }
        } else {
          final cardToMove = move.card;
          final cardsInPile = _cards(move.from);

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

          if (!rules.canPick(cardsToPick, move.from)) {
            return MoveForbidden(
                'cannot pick the card(s) $cardsToPick from ${move.from}', move);
          }
          if (!rules.canPlace(cardsToPick, move.to, _cards(move.to))) {
            return MoveForbidden(
                'cannot place the card(s) $cardsToPick on ${move.to}', move);
          }

          targetMove = Move(cardsToPick, move.from, move.to);
        }
    }

    if (doMove) {
      _doMoveCards(targetMove);
    }

    return MoveSuccess(targetMove);
  }

  MoveResult tryQuickPlace(PlayCard card, Pile from, {bool doMove = true}) {
    final cardsInHand = switch (from) {
      Tableau() || Foundation() => [
          ..._cards(from)
              .getRange(_cards(from).indexOf(card), _cards(from).length)
        ],
      Draw() || Discard() => [card],
    };

    final foundationIndexes = RollingIndexIterator(
      count: rules.numberOfFoundationPiles,
      start: 0,
      direction: 1,
    );

    final tableauIndexes = RollingIndexIterator(
      count: rules.numberOfTableauPiles,
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

  bool get canUndo => _currentMoveIndex > 0;
  bool get canRedo => _currentMoveIndex < _history.length - 1;

  void undoMove() {
    if (_currentMoveIndex == 0) {
      return;
    }
    _restoreFromHistory(_currentMoveIndex - 1);
    _currentMoveIndex--;
    _undoCount++;
    _isUndoing = true;

    _postCheckAfterPlacement();

    notifyListeners();
  }

  void redoMove() {
    if (_currentMoveIndex >= _history.length - 1) {
      return;
    }
    _currentMoveIndex++;
    _restoreFromHistory(_currentMoveIndex);
    _isUndoing = false;

    _postCheckAfterPlacement();

    notifyListeners();
  }

  Iterable<(PlayCard card, Pile pile)> _getAllVisibleCards() sync* {
    for (final t in rules.allTableaus) {
      for (final c in _cards(t)) {
        yield (c, t);
      }
    }
    for (final f in rules.allFoundations) {
      if (_cards(f).isNotEmpty) {
        yield (_cards(f).last, f);
      }
    }

    if (_cards(const Discard()).isNotEmpty) {
      yield (_cards(const Discard()).last, const Discard());
    }
  }

  void highlightPossibleMoves() {
    if (_hintedCards != null) {
      return;
    }

    final movableCards = <PlayCard>[];
    for (final (card, from) in _getAllVisibleCards()) {
      if (tryQuickPlace(card, from, doMove: false) is MoveSuccess) {
        movableCards.add(card);
      }
    }
    if (movableCards.isEmpty) {
      final drawPile = _cards(const Draw());
      if (drawPile.isNotEmpty) {
        movableCards.add(drawPile.last);
      }
    }

    _hintedCards = movableCards;
    notifyListeners();

    Future.delayed(const Duration(seconds: 1), () {
      if (_hintedCards != null) {
        _hintedCards = null;
        notifyListeners();
      }
    });
  }

  void _doAutoMove() async {
    final autoMoveDelay = cardMoveAnimation.duration * 0.8;

    bool handled;

    do {
      await Future.delayed(autoMoveDelay * timeDilation);
      handled = false;
      for (final move in rules.autoMoveStrategy(_autoMoveLevel, _cards)) {
        final result = tryMove(move);
        if (result is MoveSuccess) {
          HapticFeedback.mediumImpact();
          handled = true;
          break;
        }
      }
    } while (handled && !isWinning);
  }

  void startAutoSolve() async {
    final autoSolveMoveDelay = cardMoveAnimation.duration * 0.5;

    if (_status == GameStatus.autoSolving) {
      return;
    }

    _status = GameStatus.autoSolving;
    notifyListeners();

    bool handled;

    do {
      handled = false;
      for (final move in rules.autoSolveStrategy(_cards)) {
        final result = tryMove(move);
        if (result is MoveSuccess) {
          HapticFeedback.mediumImpact();
          handled = true;
          await Future.delayed(autoSolveMoveDelay * timeDilation);
          break;
        }
      }
    } while (handled && !isWinning);
  }

  void _updateHistory(Action recentAction) {
    if (recentAction is! GameStart) {
      _currentMoveIndex++;
    }

    if (_history.length > _currentMoveIndex) {
      _history.removeRange(_currentMoveIndex, _history.length);
    }

    final newHistory = GameHistory(
      _cards.copy(),
      recentAction,
    );

    _history.add(newHistory);
  }

  void _restoreFromHistory(int historyIndex) {
    final history = _history[historyIndex];

    _cards = history.cards.copy();
  }

  void _postCheckAfterPlacement() {
    final isWinning = rules.winConditions(_cards);
    if (isWinning) {
      _status = GameStatus.ended;
      _stopWatch.stop();
    }
    _canAutoSolve = !isWinning && rules.canAutoSolve(_cards);
  }
}

class GameHistory {
  GameHistory(
    this.cards,
    this.action,
  );

  final PlayCards cards;
  final Action action;
}
