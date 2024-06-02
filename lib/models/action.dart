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

class Undo extends Action {
  final Move _move;

  const Undo(this._move);

  @override
  Move? get move => _move;

  @override
  String toString() => 'Undo($move))';
}

class Redo extends Action {
  final Move _move;

  const Redo(this._move);

  @override
  Move? get move => _move;

  @override
  String toString() => 'Redo($move))';
}

class MoveIntent {
  final Pile from;
  final Pile to;
  final PlayCard? card;

  const MoveIntent(this.from, this.to, [this.card]);

  @override
  String toString() => 'MoveIntent($from => $to, card=$card)';
}
