import '../../move_check.dart';
import '../../pile.dart';
import '../solitaire.dart';
import 'golf.dart';

class PuttPutt extends Golf {
  PuttPutt();

  @override
  String get name => 'Putt Putt';

  @override
  String get tag => 'putt-putt';

  @override
  GameSetup construct() {
    final setup = super.construct();

    return setup.modify(
      const Waste(0),
      (props) => props.copyWith(
        placeable: const [BuildupOneRankNearer(wrapping: true)],
      ),
    );
  }
}
