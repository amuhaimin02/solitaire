import 'action.dart';
import 'card.dart';
import 'pile.dart';

sealed class MoveResult {
  const MoveResult();
}

class MoveForbidden extends MoveResult {
  final String reason;

  const MoveForbidden(this.reason);

  @override
  String toString() => 'MoveForbidden($reason)';
}

class MoveSuccess extends MoveResult {
  final Action action;

  const MoveSuccess(this.action);

  @override
  String toString() => 'MoveSuccess($action)';
}

class MoveNotDone extends MoveResult {
  final String reason;
  final PlayCard? card;
  final Pile from;

  const MoveNotDone(this.reason, this.card, this.from);

  @override
  String toString() => 'MoveNotDone($reason)';
}
