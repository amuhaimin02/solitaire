enum Suit {
  diamond('♢', 'R'),
  club('♧', 'B'),
  heart('♡', 'R'),
  spade('♤', 'B');

  final String symbol;

  final String group;

  const Suit(this.symbol, this.group);
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
  static final fullCardSet = List<PlayCard>.unmodifiable([
    for (final suit in Suit.values)
      for (final value in Value.values) PlayCard(suit, value)
  ]);

  final Suit suit;
  final Value value;

  final bool flipped;

  const PlayCard(this.suit, this.value, {this.flipped = false});

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
    return other is PlayCard && suit == other.suit && value == other.value;
  }

  @override
  int get hashCode => Object.hash(suit, value);

  bool get isFacingUp => flipped == false;

  bool get isFacingDown => flipped == true;

  PlayCard faceDown() {
    if (flipped == true) return this;
    return PlayCard(suit, value, flipped: true);
  }

  PlayCard faceUp() {
    if (flipped == false) return this;
    return PlayCard(suit, value, flipped: false);
  }

  bool sameSuit(PlayCard other) {
    return suit == other.suit;
  }

  bool sameColor(PlayCard other) {
    return suit.group == other.suit.group;
  }

  bool oneRankOver(PlayCard other) {
    return value.rank == other.value.rank + 1;
  }

  bool oneRankUnder(PlayCard other) {
    return value.rank == other.value.rank - 1;
  }
}
