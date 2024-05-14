import 'card.dart';

sealed class Pile {
  const Pile();
}

class Draw extends Pile {
  const Draw();

  @override
  String toString() => "Draw";
}

class Discard extends Pile {
  const Discard();
  @override
  String toString() => "Discard";
}

class Foundation extends Pile {
  final int index;

  const Foundation(this.index);

  @override
  String toString() => "Foundation($index)";
}

class Tableau extends Pile {
  final int index;

  const Tableau(this.index);

  @override
  String toString() => "Tableau($index)";
}

sealed class Action {}

class Move extends Action {
  final PlayCardList cards;
  final Pile from;
  final Pile to;

  Move(this.cards, this.from, this.to);

  @override
  String toString() => 'Move($cards, $from => $to)';
}

class GameStart extends Action {
  @override
  String toString() => 'GameStart';
}

typedef PileGetter = PlayCardList Function(Pile pile);
