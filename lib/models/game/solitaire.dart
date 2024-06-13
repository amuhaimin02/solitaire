import 'dart:ui';

import '../../config.dart';
import '../../utils/types.dart';
import '../move_attempt.dart';
import '../move_check.dart';
import '../move_event.dart';
import '../pile.dart';
import '../pile_property.dart';

abstract class SolitaireGame {
  SolitaireGame() {
    _setup = construct();
  }

  late final GameSetup _setup;

  String get name;

  String get family;

  String get tag;

  LayoutProperty<Size> get tableSize;

  GameSetup construct();

  List<MoveCheck> get objectives;

  int determineScore(MoveEvent event) => 0;

  List<MoveCheck>? get canAutoSolve => null;

  List<MoveAttemptTo> get quickMove => const [];

  List<MoveAttempt> get premove => const [];

  List<MoveAttempt> get postMove => const [];

  List<MoveAttempt> get autoSolve => const [];

  @override
  String toString() => name;

  GameSetupMap get setup {
    if (refreshGameSetupOnReload) {
      return construct().setup;
    }
    return _setup.setup;
  }
}

class GameSetup {
  const GameSetup({required this.setup});

  final GameSetupMap setup;

  GameSetup adjust(Pile pile, PileProperty Function(PileProperty) changeProp) {
    return GameSetup(
      setup: {
        ...setup,
        pile: changeProp(setup.get(pile)),
      },
    );
  }
}

typedef GameSetupMap = Map<Pile, PileProperty>;
