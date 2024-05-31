import 'package:collection/collection.dart';
import 'package:xrandom/xrandom.dart';

import '../services/card_shuffler.dart';
import 'card.dart';
import 'card_list.dart';
import 'pile.dart';
import 'play_data.dart';
import 'play_table.dart';

abstract class PileAction {
  const PileAction();

  PlayTable run(Pile pile, PlayTable table, GameMetadata metadata);

  static PlayTable runAll({
    required PlayTable originTable,
    required List<PileAction> actions,
    required Pile pile,
    required GameMetadata metadata,
  }) {
    PlayTable updatedTable = originTable;
    for (final action in actions) {
      updatedTable = action.run(pile, updatedTable, metadata);
    }
    return updatedTable;
  }
}

class AddDeck extends PileAction {
  const AddDeck({this.count = 1});

  final int count;

  @override
  PlayTable run(Pile pile, PlayTable table, GameMetadata metadata) {
    final existingCards = table.get(pile);
    final newCards = const CardShuffler()
        .generateShuffledDeck(Xrandom(metadata.randomSeed.hashCode));
    return table.modify(pile, [...existingCards, ...newCards]);
  }
}

class FlipAllCardsFaceUp extends PileAction {
  const FlipAllCardsFaceUp();

  @override
  PlayTable run(Pile pile, PlayTable table, GameMetadata metadata) {
    return table.modify(pile, table.get(pile).allFaceUp);
  }
}

class FlipAllCardsFaceDown extends PileAction {
  const FlipAllCardsFaceDown();

  @override
  PlayTable run(Pile pile, PlayTable table, GameMetadata metadata) {
    return table.modify(pile, table.get(pile).allFaceDown);
  }
}

class FlipTopmostCardFaceUp extends PileAction {
  const FlipTopmostCardFaceUp();

  @override
  PlayTable run(Pile pile, PlayTable table, GameMetadata metadata) {
    final cardsOnPile = table.get(pile);
    return table.modify(pile, [
      ...cardsOnPile.slice(0, cardsOnPile.length - 1),
      cardsOnPile.last.faceUp()
    ]);
  }
}

class PickCardsFrom extends PileAction {
  const PickCardsFrom(this.fromPile, {required this.count});

  final Pile fromPile;

  final int count;

  @override
  PlayTable run(Pile pile, PlayTable table, GameMetadata metadata) {
    final cardsFromPile = table.get(fromPile);
    final List<PlayCard> cardsToPick, remainingCards;
    if (cardsFromPile.length >= count) {
      cardsToPick = cardsFromPile.slice(
          cardsFromPile.length - count, cardsFromPile.length);
      remainingCards = cardsFromPile.slice(0, cardsFromPile.length - count);
    } else {
      cardsToPick = cardsFromPile;
      remainingCards = [];
    }

    return table.modifyMultiple({
      fromPile: remainingCards,
      pile: cardsToPick,
    });
  }
}
