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

enum Rank {
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
  final int value;

  const Rank(this.symbol, this.value);
}

class PlayCard {
  static final numberOfCardsInDeck = Suit.values.length * Rank.values.length;

  final Suit suit;
  final Rank rank;

  final bool flipped;

  final int deck;

  const PlayCard(this.suit, this.rank, {this.deck = 1, this.flipped = false});

  @override
  String toString() {
    if (flipped) {
      return '[${rank.symbol}${suit.symbol}]';
    } else {
      return '(${rank.symbol}${suit.symbol})';
    }
  }

  @override
  bool operator ==(Object other) {
    return other is PlayCard &&
        suit == other.suit &&
        rank == other.rank &&
        deck == other.deck;
  }

  @override
  int get hashCode => Object.hash(suit, rank, deck);

  bool get isFacingUp => flipped == false;

  bool get isFacingDown => flipped == true;

  PlayCard faceDown() {
    if (flipped == true) return this;
    return PlayCard(suit, rank, deck: deck, flipped: true);
  }

  PlayCard faceUp() {
    if (flipped == false) return this;
    return PlayCard(suit, rank, deck: deck, flipped: false);
  }

  bool isSameSuitWith(PlayCard other) {
    return suit == other.suit;
  }

  bool isSameSuitAndRank(PlayCard other) {
    return suit == other.suit && rank == other.rank;
  }

  bool isSameColor(PlayCard other) {
    return suit.color == other.suit.color;
  }

  bool isOneRankOver(PlayCard other) {
    return rank.value == other.rank.value + 1;
  }

  bool isOneRankUnder(PlayCard other) {
    return rank.value == other.rank.value - 1;
  }
}
