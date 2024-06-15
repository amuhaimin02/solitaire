import 'dart:math';

import 'package:collection/collection.dart';

import '../models/card.dart';

class PlayCardGenerator {
  const PlayCardGenerator();

  List<PlayCard> generateOrderedDeck(
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

  List<PlayCard> generateShuffledDeck(Random random,
      {int numberOfDecks = 1, bool Function(PlayCard card)? criteria}) {
    return generateOrderedDeck(numberOfDecks: numberOfDecks, criteria: criteria)
      ..shuffle(random);
  }

  List<PlayCard> generateOrderedSuit(Suit suit, {Rank? from, Rank? to}) {
    final fromIndex = from != null ? Rank.values.indexOf(from) : 0;
    final toIndex =
        to != null ? Rank.values.indexOf(to) + 1 : Rank.values.length;

    return Rank.values
        .slice(fromIndex, toIndex)
        .map((rank) => PlayCard(suit, rank))
        .toList();
  }
}
