import 'dart:math';

import 'package:flutter/material.dart' hide Action;
import 'package:flutter/services.dart';

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

  late Rules rules = Klondike();

  late bool _isWinning;

  late List<GameHistory> _history;

  late int _currentMoveIndex;

  late int _reshuffleCount;

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

  int get reshuffleCount => _reshuffleCount;

  int get undoCount => _undoCount;

  bool get isUndoing => _isUndoing;

  bool get canAutoSolve => _canAutoSolve;

  Action? get latestAction {
    if (_isUndoing && _currentMoveIndex < _history.length - 1) {
      return _history[_currentMoveIndex + 1].action;
    } else {
      return _history[_currentMoveIndex].action;
    }
  }

  bool get isOnStartingPoint => _history.length == 1;

  Iterable<PlayCardList> get allFoundationPiles => Iterable.generate(
      rules.numberOfFoundationPiles, (index) => pile(Foundation(index)));
  Iterable<PlayCardList> get allTableauPiles => Iterable.generate(
      rules.numberOfTableauPiles, (index) => pile(Tableau(index)));

  void startNewGame({bool keepSeed = false}) {
    if (!keepSeed) {
      _gameSeed = CustomPRNG.generateSeed(length: 12);
    }
    resetStates();
    setupPiles();

    // testCustomLayout();

    _updateHistory(GameStart());

    _stopWatch
      ..reset()
      ..start();

    notifyListeners();
  }

  void testCustomLayout() {
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
  }

  void restartGame() {
    startNewGame(keepSeed: true);
  }

  void resetStates() {
    _isWinning = false;
    _history = [];
    _currentMoveIndex = 0;
    _reshuffleCount = 0;
    _undoCount = 0;
    _isUndoing = false;
    _canAutoSolve = false;
  }

  void setupPiles() {
    // Clear up tables, and set up new draw pile
    _drawPile = rules.prepareDrawPile(CustomPRNG.create(_gameSeed)).allFaceDown;
    _foundationPile = List.generate(Suit.values.length, (index) => []);
    _discardPile = [];
    _tableauPile = List.generate(rules.numberOfTableauPiles, (index) => []);

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

  void restoreToDrawPile() {
    final drawPile = pile(const Draw());
    for (final f in allFoundationPiles) {
      drawPile.addAll(f.extractAll().allFaceDown);
    }
    for (final t in allTableauPiles) {
      drawPile.addAll(t.extractAll().allFaceDown);
    }
    drawPile.addAll(pile(const Discard()).extractAll().allFaceDown);
    notifyListeners();
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
    print('trying move $move');
    switch (move.from) {
      case Draw():
        if (move.to != const Discard()) {
          return MoveForbidden(
              'cannot move cards from draw pile to pile other than discard',
              move);
        }
        final cardsInDrawPile = pile(const Draw());

        if (cardsInDrawPile.isEmpty) {
          // Refresh draw pile
          final cardsInDiscardPile = pile(const Discard());

          _reshuffleCount++;

          return MoveSuccess(_doMoveCards(
            Move(
              cardsInDiscardPile.reversed.toList().allFaceDown,
              const Discard(),
              const Draw(),
            ),
          ));
        } else {
          return MoveSuccess(_doMoveCards(
            Move(
              [cardsInDrawPile.last.faceUp()],
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

        if (cardToMove != null) {
          cardsToPick = cardsInPile.getUntilLast(cardToMove);
        } else {
          if (cardsInPile.isEmpty) {
            return MoveNotDone(null, move.from);
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

    return MoveNotDone(card, from);
  }

  bool get canUndo => _currentMoveIndex > 0;
  bool get canRedo => _currentMoveIndex < _history.length - 1;

  void undoMove() {
    if (_currentMoveIndex == 0) {
      print('Cannot undo any further as the game is already at the beginning');
      return;
    }
    _restoreFromHistory(_currentMoveIndex - 1);
    _currentMoveIndex--;
    _undoCount++;
    _isUndoing = true;
    notifyListeners();
  }

  void redoMove() {
    if (_currentMoveIndex >= _history.length - 1) {
      print('Cannot red any further as the game is already at latest point');
      return;
    }
    _currentMoveIndex++;
    _restoreFromHistory(_currentMoveIndex);
    _isUndoing = false;
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
      _drawPile,
      _discardPile,
      _tableauPile,
      _foundationPile,
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

    print(
        'Restored from [$historyIndex]: T=${_tableauPile.map((e) => e.length)}');
  }

  void _postCheckAfterPlacement() {
    if (rules.winConditions(pile)) {
      HapticFeedback.heavyImpact();
      _isWinning = true;
    }

    _canAutoSolve = !_isWinning && rules.canAutoSolve(pile);
  }
}

class GameHistory {
  GameHistory(
    PlayCardList drawPile,
    PlayCardList discardPile,
    List<PlayCardList> tableauPile,
    List<PlayCardList> foundationPile,
    this.action,
  )   : drawPile = drawPile.copy(),
        discardPile = discardPile.copy(),
        tableauPile = tableauPile.copy(),
        foundationPile = foundationPile.copy();

  final PlayCardList drawPile;
  final PlayCardList discardPile;
  final List<PlayCardList> tableauPile;
  final List<PlayCardList> foundationPile;
  final Action action;
}
