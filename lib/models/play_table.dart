import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import 'card.dart';
import 'game/solitaire.dart';
import 'pile.dart';

@immutable
class PlayTable {
  final Map<Pile, List<PlayCard>> _allCards;

  const PlayTable._(this._allCards);

  factory PlayTable.empty() {
    return PlayTable._(Map.unmodifiable({}));
  }

  factory PlayTable.fromMap(Map<Pile, List<PlayCard>> cards) {
    return PlayTable._(
      UnmodifiableMapView({
        for (final item in cards.entries)
          item.key: List.unmodifiable(item.value),
      }),
    );
  }

  factory PlayTable.fromGame(SolitaireGame game) {
    return PlayTable._(
      UnmodifiableMapView({
        for (final pile in game.piles.keys) pile: List.empty(growable: false),
      }),
    );
  }

  List<PlayCard> get(Pile pile) {
    final cards = _allCards[pile];
    if (cards == null) {
      return List.empty(growable: false);
    }
    return UnmodifiableListView(cards);
  }

  Map<Pile, List<PlayCard>> get allCards => UnmodifiableMapView(_allCards);

  List<PlayCard> get drawPile => get(const Draw());

  List<PlayCard> get discardPile => get(const Discard());

  List<PlayCard> foundationPile(int index) => get(Foundation(index));

  List<PlayCard> tableauPile(int index) => get(Tableau(index));

  Iterable<Tableau> get allTableauPiles {
    return _allCards.keys.whereType<Tableau>();
  }

  Iterable<Foundation> get allFoundationPiles {
    return _allCards.keys.whereType<Foundation>();
  }

  PlayTable modify(Pile pile, List<PlayCard> cards) {
    return PlayTable._(
      UnmodifiableMapView({..._allCards, pile: cards}),
    );
  }

  PlayTable modifyMultiple(Map<Pile, List<PlayCard>> updates) {
    return PlayTable._(
      UnmodifiableMapView({
        ..._allCards,
        for (final item in updates.entries) item.key: item.value,
      }),
    );
  }
}
