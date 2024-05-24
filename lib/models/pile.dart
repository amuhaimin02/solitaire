import 'dart:math';

import 'package:collection/collection.dart';

import '../utils/lists.dart';
import 'card.dart';
import 'rules/rules.dart';

sealed class Pile {
  const Pile();
}

class Draw extends Pile {
  const Draw();

  @override
  String toString() => "Draw";

  @override
  bool operator ==(Object other) => other is Draw;

  @override
  int get hashCode => 0;
}

class Discard extends Pile {
  const Discard();
  @override
  String toString() => "Discard";

  @override
  bool operator ==(Object other) => other is Discard;

  @override
  int get hashCode => 0;
}

class Foundation extends Pile {
  final int index;

  const Foundation(this.index);

  @override
  bool operator ==(Object other) => other is Foundation && other.index == index;

  @override
  int get hashCode => Object.hash(index, null);

  @override
  String toString() => "Foundation($index)";
}

class Tableau extends Pile {
  final int index;

  const Tableau(this.index);

  @override
  bool operator ==(Object other) => other is Tableau && other.index == index;

  @override
  int get hashCode => Object.hash(index, null);

  @override
  String toString() => "Tableau($index)";
}

sealed class Action {}

class Move extends Action {
  final PlayCardList cards;
  final Pile from;
  final Pile to;

  Move(this.cards, this.from, this.to);

  @override
  String toString() => 'Move($cards, $from => $to)';
}

class MoveIntent {
  final Pile from;
  final Pile to;

  PlayCard? card;

  MoveIntent(this.from, this.to, [this.card]);

  @override
  String toString() => 'MoveIntent($from => $to, card=$card)';
}

sealed class MoveResult {
  const MoveResult();
}

class MoveForbidden extends MoveResult {
  final String reason;

  final MoveIntent move;

  const MoveForbidden(this.reason, this.move);

  @override
  String toString() => "MoveForbidden($reason)";
}

class MoveSuccess extends MoveResult {
  final Move move;

  const MoveSuccess(this.move);

  @override
  String toString() => "MoveSuccess($move)";
}

class MoveNotDone extends MoveResult {
  final String reason;
  final PlayCard? card;
  final Pile from;

  const MoveNotDone(this.reason, this.card, this.from);

  @override
  String toString() => "MoveNotDone($reason)";
}

class GameStart extends Action {
  @override
  String toString() => 'GameStart';
}

typedef PlayCardList = List<PlayCard>;

extension PlayCardListExtension on List<PlayCard> {
  PlayCardList get allFaceDown => map((e) => e.faceDown()).toList();

  PlayCardList get allFaceUp => map((e) => e.faceUp()).toList();

  PlayCardList pickLast([int amount = 1]) {
    final startRange = max(length - amount, 0);
    final endRange = length;
    final cardsToPick = getRange(startRange, endRange).toList();
    removeRange(startRange, endRange);
    return cardsToPick;
  }

  PlayCardList getLast([int amount = 1]) {
    final startRange = max(length - amount, 0);
    final endRange = length;
    return getRange(startRange, endRange).toList();
  }

  PlayCardList getUntilLast(PlayCard card) {
    if (isNotEmpty && last == card) {
      return [card];
    }

    final startRange = indexOf(card);
    if (startRange < 0) {
      throw RangeError('Card $card is not in list $this');
    }
    return getRange(startRange, length).toList();
  }

  bool followRankDecreasingOrder() {
    int? lastRank;
    for (final card in this) {
      // Ensure cards in hand follows their ranking order based on numbers (e.g. A < 2 < 3)
      if (lastRank != null) {
        return card.rank.value == lastRank - 1;
      }
      lastRank = card.rank.value;
    }
    return true;
  }

  bool get isSingle => length == 1;

  bool get isAllFacingUp => every((e) => e.isFacingUp);

  bool get isAllFacingDown => every((e) => e.isFacingDown);
}

class PlayCardGenerator {
  static PlayCardList generateOrderedDeck(
      {int numberOfDecks = 1, bool Function(PlayCard card)? criteria}) {
    return List.generate(numberOfDecks, (times) {
      final cards = <PlayCard>[];
      for (final suit in Suit.values) {
        for (final value in Rank.values) {
          final card = PlayCard(suit, value, deck: times);
          if (criteria == null || criteria(card)) {
            cards.add(card);
          }
        }
      }
      return cards;
    }).flattened.toList();
  }
}

class PlayCards {
  final Map<Pile, PlayCardList> _cards;

  const PlayCards(this._cards);

  factory PlayCards.fromGame(SolitaireGame game) {
    return PlayCards({
      for (final pile in game.piles) pile: [],
    });
  }

  PlayCardList call(Pile pile) {
    return _cards[pile] ?? [];
  }

  PlayCards copy() {
    return PlayCards({
      for (final pile in _cards.keys) pile: _cards[pile]!.copy(),
    });
  }
}
