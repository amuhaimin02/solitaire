import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/iterators.dart';
import '../utils/lists.dart';
import 'card.dart';
import 'game_rules.dart';

class GameState extends ChangeNotifier {
  late int _gameSeed;

  late PlayCardList _drawPile;

  late List<PlayCardList> _foundationPile;

  late PlayCardList _discardPile;

  late List<PlayCardList> _tableauPile;

  late GameRules gameRules = Klondike();

  late bool _isWinning;

  late List<GameHistory> _history;

  late int _currentMoveIndex;

  late int _reshuffleCount;

  late int _undoCount;

  late bool _isUndoing;

  late bool _canAutoSolve;

  bool _showDebugPanel = false;

  final _stopWatch = Stopwatch();

  GameState() {
    startNewGame();
  }

  bool get isWinning => _isWinning;

  int get gameSeed => _gameSeed;

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
      gameRules.numberOfFoundationPiles, (index) => pile(Foundation(index)));
  Iterable<PlayCardList> get allTableauPiles => Iterable.generate(
      gameRules.numberOfTableauPiles, (index) => pile(Tableau(index)));

  void startNewGame({bool keepSeed = false}) {
    if (!keepSeed) {
      _gameSeed = DateTime.now().millisecondsSinceEpoch;
    }

    resetStates();
    setupPiles();
    distributeToTableau();

    // testCustomLayout();

    _updateHistory(GameStart());

    _stopWatch
      ..reset()
      ..start();

    notifyListeners();
  }

  void testCustomLayout() {
    _drawPile = [
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
    _drawPile = PlayCard.newShuffledDeck(Random(_gameSeed))
        .map((c) => c.faceDown())
        .toList();
    _foundationPile = List.generate(Suit.values.length, (index) => []);
    _discardPile = [];
    _tableauPile = List.generate(gameRules.numberOfTableauPiles, (index) => []);
  }

  void distributeToTableau() {
    for (int i = 0; i < gameRules.numberOfTableauPiles; i++) {
      final tableau = pile(Tableau(i));
      for (int k = 0; k <= i; k++) {
        final card = pile(Draw()).removeLast();

        if (k == i) {
          // Last card, turn face up
          tableau.add(card.faceUp());
        } else {
          // Any other card, keep face down
          tableau.add(card.faceDown());
        }
      }
    }
  }

  void testDistributeToOtherPiles() {
    for (int i = 0; i < gameRules.numberOfFoundationPiles; i++) {
      for (int j = 0; i < j; j++) {
        pile(Foundation(i)).add(pile(Draw()).removeLast().faceUp());
      }
    }
    for (int i = 0; i < 7; i++) {
      pile(Discard()).add(pile(Draw()).removeLast().faceUp());
    }
  }

  void restoreToDrawPile() {
    final drawPile = pile(Draw());
    for (final f in allFoundationPiles) {
      drawPile.addAll(f.extractAll().allFaceDown);
    }
    for (final t in allTableauPiles) {
      drawPile.addAll(t.extractAll().allFaceDown);
    }
    drawPile.addAll(pile(Discard()).extractAll().allFaceDown);
    notifyListeners();
  }

  PlayCardList pile(CardLocation location) {
    return switch (location) {
      Draw() => _drawPile,
      Discard() => _discardPile,
      Foundation(index: var index) => _foundationPile[index],
      Tableau(index: var index) => _tableauPile[index],
    };
  }

  void pickFromDrawPile() {
    final pickedCard = pile(Draw()).removeLast();

    pile(Discard()).add(pickedCard.faceUp());

    _updateHistory(MoveCards([pickedCard], Draw(), Discard()));

    notifyListeners();
  }

  void refreshDrawPile() {
    final remainderCards =
        pile(Discard()).reversed.map((c) => c.faceDown()).toList();

    pile(Draw())
      ..clear()
      ..addAll(remainderCards);
    pile(Discard()).clear();

    _updateHistory(MoveCards([...remainderCards], Discard(), Draw()));

    _reshuffleCount++;

    notifyListeners();
  }

  void placeCards(MoveCards action) {
    try {
      final cardsInHand = action.cards.copy();

      // Make validation first before altering card in play
      // _validatePlacement(cardsInHand, action.from, action.to);

      _checkAndRemoveCards(cardsInHand, action.from);

      _placeCardsOnTable(cardsInHand, action.to);

      _postCheckAfterPlacement();

      _updateHistory(action);

      _isUndoing = false;
    } catch (e) {
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  CardLocation? tryQuickPlace(PlayCard card, CardLocation from) {
    final cardsInHand = switch (from) {
      Tableau() || Foundation() => [
          ...pile(from).getRange(pile(from).indexOf(card), pile(from).length)
        ],
      Draw() || Discard() => [card],
    };

    if (from is Tableau) {
      if (!gameRules.canPick(cardsInHand, from)) {
        return null;
      }
    }

    final foundationIndexes = RollingIndexIterator(
      count: gameRules.numberOfFoundationPiles,
      start: 0,
      direction: 1,
    );

    final tableauIndexes = RollingIndexIterator(
      count: gameRules.numberOfTableauPiles,
      start: from is Tableau ? from.index : 0,
      direction: 1,
      startInclusive: from is! Tableau,
    );

    // Try placing on foundation pile first
    // For cards from foundation, no need to move to other foundations
    if (from is! Foundation) {
      for (final i in foundationIndexes) {
        final foundation = Foundation(i);
        if (gameRules.canPlace(cardsInHand, foundation, pile(foundation))) {
          placeCards(MoveCards(cardsInHand, from, foundation));
          return foundation;
        }
      }
    }

    // Try placing on tableau next
    for (final i in tableauIndexes) {
      final tableau = Tableau(i);
      if (gameRules.canPlace(cardsInHand, tableau, pile(tableau))) {
        placeCards(MoveCards(cardsInHand, from, tableau));
        return tableau;
      }
    }

    return null;
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

  void _checkAndRemoveCards(PlayCardList cardsInHand, CardLocation location) {
    final cardsOnTable = pile(location);

    cardsOnTable.removeRange(
        cardsOnTable.length - cardsInHand.length, cardsOnTable.length);

    if (cardsOnTable.isNotEmpty) {
      cardsOnTable.last = cardsOnTable.last.faceUp();
    }
  }

  void _placeCardsOnTable(PlayCardList cardsInHand, CardLocation location) {
    final cardsOnTable = pile(location);

    // Move all cards on hand to location
    cardsOnTable.addAll(cardsInHand);
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
    if (gameRules.winConditions(this)) {
      HapticFeedback.heavyImpact();
      _isWinning = true;
    }

    _canAutoSolve = !_isWinning && gameRules.canAutoSolve(this);
  }

  bool get isDebugPanelShowing => _showDebugPanel;

  void toggleDebugPanel() {
    _showDebugPanel = !_showDebugPanel;
    notifyListeners();
  }
}

sealed class CardLocation {}

class Draw extends CardLocation {
  @override
  String toString() => "Draw";
}

class Discard extends CardLocation {
  @override
  String toString() => "Discard";
}

class Foundation extends CardLocation {
  final int index;

  Foundation(this.index);

  @override
  String toString() => "Foundation($index)";
}

class Tableau extends CardLocation {
  final int index;

  Tableau(this.index);

  @override
  String toString() => "Tableau($index)";
}

class PickedCards {
  final PlayCardList cards;
  final CardLocation location;

  PickedCards(this.cards, this.location);
}

sealed class Action {}

class MoveCards extends Action {
  final PlayCardList cards;
  final CardLocation from;
  final CardLocation to;

  MoveCards(this.cards, this.from, this.to);

  @override
  String toString() => 'MoveCards($cards, $from => $to)';
}

class GameStart extends Action {
  @override
  String toString() => 'GameStart';
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
