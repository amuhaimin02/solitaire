import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../utils/types.dart';
import 'card.dart';
import 'card_list.dart';
import 'game/solitaire.dart';
import 'pile.dart';

typedef PlayCardMap = IMap<Pile, PlayCardList>;

@immutable
class PlayTable {
  final IMap<Pile, PlayCardList> _cardMap;

  const PlayTable._(this._cardMap);

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
    return _cardMap[pile] ?? const PlayCardList.empty();
  }

  Iterable<Pile> allPiles() {
    return _cardMap.keys;
  }

  Iterable<T> allPilesOfType<T extends Pile>() {
    return _cardMap.keys.whereType<T>();
  }

  T? getEmptyPileOfType<T extends Pile>() {
    return allPilesOfType<T>().firstWhereOrNull((p) => get(p).isEmpty);
  }

  PlayCardMap get allCards => _cardMap;

  @useResult
  PlayTable clear(Pile pile) {
    return PlayTable._(_cardMap.add(pile, const PlayCardList.empty()));
  }

  @useResult
  PlayTable change(Pile pile, PlayCardList cards) {
    return PlayTable._(_cardMap.add(pile, cards));
  }

  @useResult
  PlayTable modify(Pile pile, PlayCard Function(PlayCard) change) {
    final existingCards = _cardMap.get(pile) ?? const PlayCardList.empty();
    return PlayTable._(
      _cardMap.add(pile, PlayCardList(existingCards.map(change))),
    );
  }

  @useResult
  PlayTable add(Pile pile, PlayCardList cards) {
    final existingCards = _cardMap.get(pile) ?? const PlayCardList.empty();
    return PlayTable._(_cardMap.add(pile, existingCards.addAll(cards)));
  }
}
