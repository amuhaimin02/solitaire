import 'card.dart';
import 'card_list.dart';
import 'pile.dart';

sealed class Action {
  const Action();

  Move? get move;
}

class Idle extends Action {
  const Idle();

  @override
  String toString() => 'Idle';

  @override
  Move? get move => null;
}

class GameStart extends Action {
  const GameStart();

  @override
  String toString() => 'GameStart';

  @override
  Move? get move => null;
}

class Move extends Action {
  final PlayCardList cards;
  final Pile from;
  final Pile to;

  const Move(this.cards, this.from, this.to);

  @override
  String toString() => 'Move($cards, $from => $to)';

  @override
  Move? get move => this;
}

class Draw extends Action {
  final PlayCardList cards;
  final Pile from;
  final Pile to;

  const Draw(this.cards, this.from, this.to);

  @override
  String toString() => 'Draw($cards, $from => $to)';

  @override
  Move? get move => Move(cards, from, to);
}

class Deal extends Action {
  final PlayCardList cards;
  final Pile pile;

  const Deal(this.cards, this.pile);

  @override
  String toString() => 'Deal($cards, $pile)';

  @override
  Move? get move => Move(cards, pile, pile);
}

class MoveIntent {
  final Pile from;
  final Pile to;
  final PlayCard? card;

  const MoveIntent(this.from, this.to, [this.card]);

  @override
  String toString() => 'MoveIntent($from => $to, card=$card)';
}
