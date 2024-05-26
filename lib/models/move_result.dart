import 'action.dart';
import 'card.dart';
import 'pile.dart';

sealed class MoveResult {
  const MoveResult();
}

class MoveForbidden extends MoveResult {
  final String reason;

  final MoveIntent move;

  const MoveForbidden(this.reason, this.move);

  @override
  String toString() => 'MoveForbidden($reason)';
}

class MoveSuccess extends MoveResult {
  final Move move;

  const MoveSuccess(this.move);

  @override
  String toString() => 'MoveSuccess($move)';
}

class MoveNotDone extends MoveResult {
  final String reason;
  final PlayCard? card;
  final Pile from;

  const MoveNotDone(this.reason, this.card, this.from);

  @override
  String toString() => 'MoveNotDone($reason)';
}
