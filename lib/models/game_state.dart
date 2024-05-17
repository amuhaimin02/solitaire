import 'package:flutter/material.dart' hide Action;

import '../animations.dart';
import '../utils/iterators.dart';
import '../utils/lists.dart';
import '../utils/prng.dart';
import 'card.dart';
import 'pile.dart';
import 'rules/klondike.dart';
import 'rules/rules.dart';

class GameState extends ChangeNotifier {
  late String _gameSeed;

  late PlayCardList _drawPile;

  late List<PlayCardList> _foundationPile;

  late PlayCardList _discardPile;

  late List<PlayCardList> _tableauPile;

  late SolitaireRules rules = Klondike();

  late bool _isWinning;

  late bool _isPreparing;

  late List<GameHistory> _history;

  late int _currentMoveIndex;

  late int _reshuffleCount;

  late int _score;

  late int _undoCount;

  late bool _isUndoing;

  late bool _canAutoSolve;

  final _stopWatch = Stopwatch();

  GameState() {
    startNewGame();
  }

  bool get isWinning => _isWinning;

  String get gameSeed => _gameSeed;

  int get moves => _currentMoveIndex;

  int get historyCount => _history.length;

  Duration get playTime => _stopWatch.elapsed;

  int get score => _score;

  int get reshuffleCount => _reshuffleCount;

  int get undoCount => _undoCount;

  bool get isUndoing => _isUndoing;

  bool get isPreparing => _isPreparing;

  bool get canAutoSolve => _canAutoSolve;

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

  bool get isJustStarting => _history.length == 1;

  Future<void> startNewGame({bool keepSeed = false}) async {
    if (!keepSeed) {
      _gameSeed = CustomPRNG.generateSeed(length: 12);
    }

    _resetStates();
    _isPreparing = true;
    _stopWatch
      ..stop()
      ..reset();

    _setupPiles();
    notifyListeners();

    await Future.delayed(cardMoveAnimation.duration * 2);
    _distributeCards();
    _updateHistory(GameStart());
    notifyListeners();

    await Future.delayed(cardMoveAnimation.duration * 5);

    _isPreparing = false;
    _stopWatch.start();

    notifyListeners();
  }

  Future<void> testCustomLayout() async {
    _resetStates();
    _setupPiles();

    _updateHistory(GameStart());

    _drawPile = [
      const PlayCard(Suit.club, Value.four).faceDown(),
      const PlayCard(Suit.heart, Value.four).faceDown(),
      const PlayCard(Suit.spade, Value.four).faceDown(),
      const PlayCard(Suit.heart, Value.five).faceDown(),
      const PlayCard(Suit.club, Value.five).faceDown(),
      const PlayCard(Suit.club, Value.six).faceDown(),
      const PlayCard(Suit.club, Value.two).faceDown(),
    ];
    _discardPile = [];
    _foundationPile = [
      [const PlayCard(Suit.heart, Value.ace)],
      [const PlayCard(Suit.spade, Value.ace)],
      [const PlayCard(Suit.diamond, Value.ace)],
      [const PlayCard(Suit.club, Value.ace)]
    ];
    _tableauPile = [
      [
        const PlayCard(Suit.heart, Value.three),
        const PlayCard(Suit.heart, Value.two),
      ],
      [
        const PlayCard(Suit.spade, Value.three),
        const PlayCard(Suit.spade, Value.two),
      ],
      [
        const PlayCard(Suit.diamond, Value.three),
        const PlayCard(Suit.diamond, Value.two),
      ],
      [const PlayCard(Suit.club, Value.three)],
      [],
      [],
      []
    ];

    notifyListeners();
  }

  void restartGame() {
    startNewGame(keepSeed: true);
  }

  void _resetStates() {
    _isWinning = false;
    _history = [];
    _currentMoveIndex = 0;
    _reshuffleCount = 0;
    _undoCount = 0;
    _score = 0;
    _isUndoing = false;
    _canAutoSolve = false;
  }

  void _setupPiles() {
    // Clear up tables, and set up new draw pile
    _drawPile = rules.prepareDrawPile(CustomPRNG.create(_gameSeed)).allFaceDown;
    _foundationPile = List.generate(Suit.values.length, (index) => []);
    _discardPile = [];
    _tableauPile = List.generate(rules.numberOfTableauPiles, (index) => []);
  }

  void _distributeCards() {
    rules.setup(pile);
  }

  void testDistributeToOtherPiles() {
    for (int i = 0; i < rules.numberOfFoundationPiles; i++) {
      for (int j = 0; i < j; j++) {
        pile(Foundation(i)).add(pile(const Draw()).removeLast().faceUp());
      }
    }
    for (int i = 0; i < 7; i++) {
      pile(const Discard()).add(pile(const Draw()).removeLast().faceUp());
    }
  }

  PlayCardList pile(Pile pile) {
    return switch (pile) {
      Draw() => _drawPile,
      Discard() => _discardPile,
      Foundation(index: var index) => _foundationPile[index],
      Tableau(index: var index) => _tableauPile[index],
    };
  }

  Move _doMoveCards(Move move) {
    print('moving $move');
    try {
      final cardsInHand = move.cards;

      final cardsOnTable = pile(move.from);

      print("cardsOnTable ${move.from} $cardsOnTable");
      print("cardsInHand $cardsInHand");

      // Check and remove cards from source pile to hand
      cardsOnTable.removeRange(
          cardsOnTable.length - cardsInHand.length, cardsOnTable.length);

      // For cards other than draw pile, flip the outermost card to make it facing up
      if (move.from != const Draw() &&
          cardsOnTable.isNotEmpty &&
          cardsOnTable.last.isFacingDown) {
        cardsOnTable.last = cardsOnTable.last.faceUp();
      }

      // Move all cards on hand to target pile
      pile(move.to).addAll(cardsInHand);

      _score = rules.determineScoreForMove(_score, move);

      _postCheckAfterPlacement();

      _updateHistory(move);

      _isUndoing = false;
    } catch (e) {
      rethrow;
    } finally {
      notifyListeners();
    }
    return move;
  }

  MoveResult tryMove(MoveIntent move) {
    switch (move.from) {
      case Draw():
        if (move.to != const Discard()) {
          return MoveForbidden(
              'cannot move cards from draw pile to pile other than discard',
              move);
        }
        final cardsInDrawPile = pile(const Draw());

        if (cardsInDrawPile.isEmpty) {
          // Try to refresh draw pile
          final cardsInDiscardPile = pile(const Discard());

          if (cardsInDiscardPile.isNotEmpty) {
            return MoveNotDone("No cards to refresh", null, move.from);
          }

          _reshuffleCount++;

          return MoveSuccess(_doMoveCards(
            Move(
              cardsInDiscardPile.reversed.toList().allFaceDown,
              const Discard(),
              const Draw(),
            ),
          ));
        } else {
          // Pick from draw pile
          final cardsToPick = cardsInDrawPile.getLast(rules.drawsPerTurn);
          return MoveSuccess(_doMoveCards(
            Move(
              [...cardsToPick.allFaceUp],
              const Draw(),
              const Discard(),
            ),
          ));
        }
      case Discard() || Foundation() || Tableau():
        if (move.to == const Draw()) {
          return MoveForbidden('cannot move cards back to draw pile', move);
        }
        if (move.from == move.to) {
          return MoveForbidden('cannot move cards back to its pile', move);
        }
        final cardToMove = move.card;
        final cardsInPile = pile(move.from);

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
        if (!rules.canPlace(cardsToPick, move.to, pile)) {
          return MoveForbidden(
              'cannot place the card(s) $cardsToPick on ${move.to}', move);
        }

        return MoveSuccess(_doMoveCards(Move(cardsToPick, move.from, move.to)));
    }
  }

  MoveResult tryQuickPlace(PlayCard card, Pile from) {
    final cardsInHand = switch (from) {
      Tableau() || Foundation() => [
          ...pile(from).getRange(pile(from).indexOf(card), pile(from).length)
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
        final result = tryMove(MoveIntent(from, Foundation(i), card));
        if (result is MoveSuccess) {
          return result;
        }
      }
    }

    // Try placing on tableau next
    for (final i in tableauIndexes) {
      final result = tryMove(MoveIntent(from, Tableau(i), card));
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

  void _updateHistory(Action recentAction) {
    if (recentAction is! GameStart) {
      _currentMoveIndex++;
    }

    if (_history.length > _currentMoveIndex) {
      _history.removeRange(_currentMoveIndex, _history.length);
    }

    final newHistory = GameHistory(
      _drawPile.copy(),
      _discardPile.copy(),
      _tableauPile.copy(),
      _foundationPile.copy(),
      recentAction,
    );

    _history.add(newHistory);
  }

  void _restoreFromHistory(int historyIndex) {
    final history = _history[historyIndex];

    _drawPile = history.drawPile.copy();
    _discardPile = history.discardPile.copy();
    _tableauPile = history.tableauPile.copy();
    _foundationPile = history.foundationPile.copy();
  }

  void _postCheckAfterPlacement() {
    _isWinning = rules.winConditions(pile);
    _canAutoSolve = !_isWinning && rules.canAutoSolve(pile);
  }
}

class GameHistory {
  GameHistory(
    this.drawPile,
    this.discardPile,
    this.tableauPile,
    this.foundationPile,
    this.action,
  );

  final PlayCardList drawPile;
  final PlayCardList discardPile;
  final List<PlayCardList> tableauPile;
  final List<PlayCardList> foundationPile;
  final Action action;
}
