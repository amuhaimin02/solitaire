import 'card_list.dart';
import 'pile.dart';

import 'card.dart';

sealed class Action {}

class GameStart extends Action {
  @override
  String toString() => 'GameStart';
}

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
