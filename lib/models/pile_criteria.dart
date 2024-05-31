import 'card.dart';
import 'pile.dart';
import 'play_table.dart';

abstract class PileCriteria {
  bool check(Pile pile, List<PlayCard> cardsToPick, PlayTable table);

  PileCriteria operator &(PileCriteria other) {
    return _PileCriteriaOr(criteria1: this, criteria2: other);
  }

  PileCriteria operator |(PileCriteria other) {
    return _PileCriteriaOr(criteria1: this, criteria2: other);
  }
}

class _PileCriteriaAnd extends PileCriteria {
  final PileCriteria criteria1;
  final PileCriteria criteria2;

  _PileCriteriaAnd({required this.criteria1, required this.criteria2});

  @override
  bool check(Pile pile, List<PlayCard> cardsToPick, PlayTable table) {
    return criteria1.check(pile, cardsToPick, table) &&
        criteria2.check(pile, cardsToPick, table);
  }
}

class _PileCriteriaOr extends PileCriteria {
  final PileCriteria criteria1;
  final PileCriteria criteria2;

  _PileCriteriaOr({required this.criteria1, required this.criteria2});

  @override
  bool check(Pile pile, List<PlayCard> cardsToPick, PlayTable table) {
    return criteria1.check(pile, cardsToPick, table) ||
        criteria2.check(pile, cardsToPick, table);
  }
}
