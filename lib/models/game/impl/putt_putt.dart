import '../../move_check.dart';
import '../../pile.dart';
import '../solitaire.dart';
import 'golf.dart';

class PuttPutt extends Golf {
  const PuttPutt();

  @override
  String get name => 'Putt Putt';

  @override
  String get family => 'Golf';

  @override
  String get tag => 'putt-putt';

  @override
  GameSetup get setup {
    return super.setup.adjust(
          const Waste(0),
          (props) => props.copyWith(
            placeable: const [BuildupOneRankNearer(wrapping: true)],
          ),
        );
  }
}
