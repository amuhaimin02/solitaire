import 'card.dart';
import 'pile.dart';

sealed class Action {
  const Action();

  bool get countAsMove => false;

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
  final List<PlayCard> cards;
  final Pile from;
  final Pile to;

  const Move(this.cards, this.from, this.to);

  @override
  bool get countAsMove => true;

  @override
  String toString() => 'Move($cards, $from => $to)';

  @override
  Move? get move => this;
}

class Deal extends Action {
  final List<PlayCard> cards;
  final Pile pile;

  const Deal(this.cards, this.pile);

  @override
  bool get countAsMove => true;

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
