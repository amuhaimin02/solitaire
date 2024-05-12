import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../utils/index_iterator.dart';
import '../utils/list_copy.dart';
import 'card.dart';
import 'game_rules.dart';

class GameState extends ChangeNotifier {
  late int _gameSeed;

  late PlayCardList drawPile;

  late List<PlayCardList> foundationPile;

  late PlayCardList discardPile;

  late List<PlayCardList> tableaux;

  late GameRules gameRules = Klondike();

  late bool _isWinning;

  late List<GameHistory> _history;

  late int _currentMoveIndex;

  late int _reshuffleCount;

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

  PlayCardList? get lastCardMoved {
    final lastAction = _history.lastOrNull?.action;
    if (lastAction is MoveCards) {
      return lastAction.cards.copy();
    } else {
      return null;
    }
  }

  void startNewGame({bool keepSeed = false}) {
    if (!keepSeed) {
      _gameSeed = DateTime.now().millisecondsSinceEpoch;
    }

    resetStates();
    setupPiles();
    distributeToTableau();
    _updateHistory(GameStart());

    _stopWatch
      ..reset()
      ..start();

    notifyListeners();
  }

  void restartGame() {
    startNewGame(keepSeed: true);
  }

  void resetStates() {
    _isWinning = false;
    _history = [];
    _currentMoveIndex = 0;
    _reshuffleCount = 0;
  }

  void setupPiles() {
    // Clear up tables, and set up new draw pile
    drawPile = PlayCard.newShuffledDeck(Random(_gameSeed))
        .map((c) => c.faceDown())
        .toList();
    foundationPile = List.generate(Suit.values.length, (index) => []);
    discardPile = [];
    tableaux = List.generate(gameRules.numberOfTableaux, (index) => []);
  }

  void distributeToTableau() {
    for (int i = 0; i < tableaux.length; i++) {
      final tableau = tableaux[i];
      for (int k = 0; k <= i; k++) {
        final card = drawPile.removeLast();

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
    for (final cards in foundationPile) {
      for (int i = 0; i < 3; i++) {
        cards.add(drawPile.removeLast().faceUp());
      }
    }
    for (int i = 0; i < 5; i++) {
      discardPile.add(drawPile.removeLast().faceUp());
    }
  }

  void pickFromDrawPile() {
    final pickedCard = drawPile.removeLast();

    discardPile.add(pickedCard.faceUp());

    _updateHistory(MoveCards([pickedCard], Draw(), Discard()));

    notifyListeners();
  }

  void refreshDrawPile() {
    final remainderCards =
        discardPile.reversed.map((c) => c.faceDown()).toList();

    drawPile = remainderCards;
    discardPile = [];

    _updateHistory(MoveCards([...remainderCards], Discard(), Draw()));

    _reshuffleCount++;

    notifyListeners();
  }

  void placeCards(MoveCards action) {
    try {
      final cardsInHand = action.cards.copy();

      // Make validation first before altering card in play
      _validatePlacement(cardsInHand, action.from, action.to);

      _checkAndRemoveCards(cardsInHand, action.from);

      _placeCardsOnTable(cardsInHand, action.to);

      _postCheckAfterPlacement();

      _updateHistory(action);
    } catch (e) {
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  bool tryQuickPlace(PlayCardList cardsInHand, CardLocation from) {
    final foundationIndexes = RollingIndexIterator(
      count: foundationPile.length,
      start: 0,
      direction: 1,
    );

    final tableauIndexes = RollingIndexIterator(
      count: tableaux.length,
      start: from is Tableau ? from.index : tableaux.length - 1,
      direction: -1,
    );

    // Try placing on foundation pile first
    // For cards from foundation, no need to move to other foundations

    if (from is! Foundation) {
      for (final i in foundationIndexes) {
        if (gameRules.canPlaceInFoundation(cardsInHand, foundationPile[i])) {
          placeCards(MoveCards(cardsInHand, from, Foundation(i)));
          return true;
        }
      }
    }

    // Try placing on tableau next
    for (final i in tableauIndexes) {
      if (gameRules.canPlaceInTableau(cardsInHand, tableaux[i])) {
        placeCards(MoveCards(cardsInHand, from, Tableau(i)));
        return true;
      }
    }

    return false;
  }

  void undoMove() {
    if (_currentMoveIndex == 0) {
      print('Cannot undo any further as the game is already at the beginning');
      return;
    }
    _restoreFromHistory(_currentMoveIndex - 1);
    _currentMoveIndex--;
    notifyListeners();
  }

  void redoMove() {
    if (_currentMoveIndex >= _history.length - 1) {
      print('Cannot red any further as the game is already at latest point');
      return;
    }
    _currentMoveIndex++;
    _restoreFromHistory(_currentMoveIndex);
    notifyListeners();
  }

  PlayCardList _getPileFromLocation(CardLocation location) {
    return switch (location) {
      Draw() => drawPile,
      Discard() => discardPile,
      Foundation(index: var index) => foundationPile[index],
      Tableau(index: var index) => tableaux[index],
    };
  }

  void _validatePlacement(
      PlayCardList cardsInHand, CardLocation from, CardLocation to) {
    print('Placing $cardsInHand} from $from to $to');

    final cardsFrom = _getPileFromLocation(from);
    final cardsToCheck = cardsFrom.slice(cardsFrom.length - cardsInHand.length);

    if (!const ListEquality<PlayCard>().equals(cardsToCheck, cardsInHand)) {
      throw AssertionError('Cards in hand should be equal with cards on table');
    }

    // Validate according to game rules
    if (to is Tableau) {
      if (!gameRules.canPlaceInTableau(cardsInHand, _getPileFromLocation(to))) {
        throw StateError('Cannot move the card(s) to this column');
      }
    } else if (to is Foundation) {
      if (!gameRules.canPlaceInFoundation(
          cardsInHand, _getPileFromLocation(to))) {
        throw StateError('Cannot move the card(s) to this foundation pile');
      }
    }
  }

  void _checkAndRemoveCards(PlayCardList cardsInHand, CardLocation location) {
    final cardsOnTable = _getPileFromLocation(location);

    cardsOnTable.removeRange(
        cardsOnTable.length - cardsInHand.length, cardsOnTable.length);

    if (cardsOnTable.isNotEmpty) {
      cardsOnTable.last = cardsOnTable.last.faceUp();
    }
  }

  void _placeCardsOnTable(PlayCardList cardsInHand, CardLocation location) {
    final cardsOnTable = _getPileFromLocation(location);

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
      drawPile,
      discardPile,
      tableaux,
      foundationPile,
      recentAction,
    );

    _history.add(newHistory);
  }

  void _restoreFromHistory(int historyIndex) {
    final history = _history[historyIndex];

    drawPile = history.drawPile.copy();
    discardPile = history.discardPile.copy();
    tableaux = history.tableaux.copy();
    foundationPile = history.foundationPile.copy();

    print('Restored from [$historyIndex]: T=${tableaux.map((e) => e.length)}');
  }

  void _postCheckAfterPlacement() {
    if (gameRules.winningCondition(foundationPile)) {
      HapticFeedback.heavyImpact();
      _isWinning = true;
    }
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
    List<PlayCardList> tableaux,
    List<PlayCardList> foundationPile,
    this.action,
  )   : drawPile = drawPile.copy(),
        discardPile = discardPile.copy(),
        tableaux = tableaux.copy(),
        foundationPile = foundationPile.copy();

  final PlayCardList drawPile;
  final PlayCardList discardPile;
  final List<PlayCardList> tableaux;
  final List<PlayCardList> foundationPile;
  final Action action;
}
