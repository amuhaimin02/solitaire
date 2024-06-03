import 'card.dart';
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
  final List<PlayCard> cards;
  final Pile from;
  final Pile to;

  const Move(this.cards, this.from, this.to);

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
  String toString() => 'Deal($cards, $pile)';

  @override
  Move? get move => Move(cards, pile, pile);
}

class Undo extends Action {
  final Action _action;

  const Undo(this._action);

  @override
  Move? get move => _action.move;

  @override
  String toString() => 'Undo($_action))';
}

class Redo extends Action {
  final Action _action;

  const Redo(this._action);

  @override
  Move? get move => _action.move;

  @override
  String toString() => 'Redo($_action))';
}

class MoveIntent {
  final Pile from;
  final Pile to;
  final PlayCard? card;

  const MoveIntent(this.from, this.to, [this.card]);

  @override
  String toString() => 'MoveIntent($from => $to, card=$card)';
}
