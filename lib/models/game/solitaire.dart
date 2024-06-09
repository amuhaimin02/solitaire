import 'dart:ui';

import '../../utils/types.dart';
import '../move_attempt.dart';
import '../move_check.dart';
import '../move_event.dart';
import '../pile.dart';
import '../pile_property.dart';

typedef GameSetup = Map<Pile, PileProperty>;

abstract class SolitaireGame {
  const SolitaireGame();

  String get name;

  String get family;

  String get tag;

  LayoutProperty<Size> get tableSize;

  GameSetup get setup;

  List<MoveCheck> get objectives;

  int determineScore(MoveEvent event) => 0;

  List<MoveCheck>? get canAutoSolve => null;

  List<MoveAttemptTo> get quickMove => const [];

  List<MoveAttempt> get premove => const [];

  List<MoveAttempt> get postMove => const [];

  List<MoveAttempt> get autoSolve => const [];

  @override
  String toString() => name;
}

extension GameSetupExtension on GameSetup {
  GameSetup adjust(Pile pile, PileProperty Function(PileProperty) changeProp) {
    return {
      ...this,
      pile: changeProp(get(pile)),
    };
  }
}
