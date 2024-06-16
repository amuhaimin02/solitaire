import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/foundation.dart';

import '../utils/types.dart';
import 'card_list.dart';
import 'game/solitaire.dart';
import 'pile.dart';

typedef PlayCardMap = IMap<Pile, PlayCardList>;

@immutable
class PlayTable {
  final IMap<Pile, PlayCardList> _allCards;

  const PlayTable._(this._allCards);

  factory PlayTable.empty() {
    return const PlayTable._(PlayCardMap.empty());
  }

  factory PlayTable.fromMap(Map<Pile, PlayCardList> cards) {
    return PlayTable._(
      PlayCardMap({
        for (final (pile, c) in cards.items) pile: PlayCardList(c),
      }),
    );
  }

  factory PlayTable.fromGame(SolitaireGame game) {
    return PlayTable._(
      PlayCardMap({
        for (final pile in game.setup.keys) pile: const PlayCardList.empty(),
      }),
    );
  }

  PlayCardList get(Pile pile) {
    return _allCards[pile] ?? const PlayCardList.empty();
  }

  Iterable<Pile> allPiles() {
    return _allCards.keys;
  }

  Iterable<T> allPilesOfType<T extends Pile>() {
    return _allCards.keys.whereType<T>();
  }

  T? getEmptyPileOfType<T extends Pile>() {
    return allPilesOfType<T>().firstWhereOrNull((p) => get(p).isEmpty);
  }

  PlayCardMap get allCards => _allCards;

  // TODO: Remove
  PlayTable modify(Pile pile, PlayCardList cards) {
    return PlayTable._(
      PlayCardMap({..._allCards.unlockView, pile: cards}),
    );
  }

  // TODO: Remove
  PlayTable modifyMultiple(Map<Pile, PlayCardList> updates) {
    return PlayTable._(
      PlayCardMap({
        ..._allCards.unlockView,
        for (final (pile, cards) in updates.items) pile: cards,
      }),
    );
  }
}
