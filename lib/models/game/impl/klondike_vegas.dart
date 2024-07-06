import '../../game_scoring.dart';
import '../../move_check.dart';
import '../../move_event.dart';
import '../../pile.dart';
import '../solitaire.dart';
import 'klondike.dart';

class KlondikeVegas extends Klondike {
  KlondikeVegas({required super.numberOfDraws});

  @override
  String get name => 'Klondike Draw $numberOfDraws (Vegas)';

  @override
  String get tag => 'klondike-vegas-draw-$numberOfDraws';

  @override
  GameSetup construct() {
    final setup = super.construct();

    return setup.modify(
      const Stock(0),
      (props) => props.copyWith(
        canTap: [
          CanRecyclePile(
            limit: numberOfDraws,
            willTakeFrom: const Waste(0),
          ),
        ],
      ),
    );
  }

  @override
  GameScoring get scoring {
    return GameScoring(
      vegasScoring: true,
      startingScore: -52,
      determineScore: (event) {
        switch (event) {
          case MoveMade(to: Foundation()):
            return 5;
          default:
            return 0;
        }
      },
    );
  }
}
