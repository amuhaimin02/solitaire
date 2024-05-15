enum Suit {
  diamond('♢', SuitColor.red),
  club('♧', SuitColor.black),
  heart('♡', SuitColor.red),
  spade('♤', SuitColor.black);

  final String symbol;

  final SuitColor color;

  const Suit(this.symbol, this.color);
}

enum SuitColor {
  red,
  black;
}

enum Value {
  ace('A', 1),
  two('2', 2),
  three('3', 3),
  four('4', 4),
  five('5', 5),
  six('6', 6),
  seven('7', 7),
  eight('8', 8),
  nine('9', 9),
  ten('10', 10),
  jack('J', 11),
  queen('Q', 12),
  king('K', 13);

  final String symbol;
  final int rank;

  const Value(this.symbol, this.rank);
}

class PlayCard {
  static final numberOfCardsInDeck = Suit.values.length * Value.values.length;

  final Suit suit;
  final Value value;

  final bool flipped;

  final int deck;

  const PlayCard(this.suit, this.value, {this.deck = 1, this.flipped = false});

  @override
  String toString() {
    if (flipped) {
      return '[${value.symbol}${suit.symbol}]';
    } else {
      return '(${value.symbol}${suit.symbol})';
    }
  }

  @override
  bool operator ==(Object other) {
    return other is PlayCard &&
        suit == other.suit &&
        value == other.value &&
        deck == other.deck;
  }

  @override
  int get hashCode => Object.hash(suit, value, deck);

  bool get isFacingUp => flipped == false;

  bool get isFacingDown => flipped == true;

  PlayCard faceDown() {
    if (flipped == true) return this;
    return PlayCard(suit, value, deck: deck, flipped: true);
  }

  PlayCard faceUp() {
    if (flipped == false) return this;
    return PlayCard(suit, value, deck: deck, flipped: false);
  }

  bool sameSuit(PlayCard other) {
    return suit == other.suit;
  }

  bool sameSuitAndRank(PlayCard other) {
    return suit == other.suit && value == other.value;
  }

  bool sameColor(PlayCard other) {
    return suit.color == other.suit.color;
  }

  bool oneRankOver(PlayCard other) {
    return value.rank == other.value.rank + 1;
  }

  bool oneRankUnder(PlayCard other) {
    return value.rank == other.value.rank - 1;
  }
}
