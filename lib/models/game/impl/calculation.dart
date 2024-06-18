import '../../card.dart';
import '../../move_action.dart';
import '../../move_check.dart';
import '../../pile.dart';
import '../solitaire.dart';
import 'sir_tommy.dart';

class Calculation extends SirTommy {
  Calculation();

  @override
  String get name => 'Calculation';

  @override
  String get tag => 'calculation';

  @override
  GameSetup construct() {
    GameSetup setup = super.construct();

    setup = setup.adjust(
      const Stock(0),
      (props) => props.copyWith(
        onSetup: [
          const FlipAllCardsFaceUp(),
          for (int i = 0; i < 4; i++)
            FindCardsAndMove(
              which: (card, cardsOnPile) => card.rank.value == i + 1,
              firstCardOnly: true,
              moveTo: Foundation(i),
            )
        ],
      ),
    );

    for (int i = 0; i < 4; i++) {
      setup = setup.adjust(
        Foundation(i),
        (props) => props.copyWith(
          pickable: const [
            CardIsOnTop(),
            PileIsNotLeftEmpty(), // Prevent moving out pre-moved cards
          ],
          placeable: [
            // King cards pretty much terminate the addition sequence
            const PileTopCardIsNotRank(Rank.king),
            // First foundation sequence: A, 2, 3, 4, ..., K (rank up 1)
            // Second foundation sequence: 2, 4, 6, 8, ..., K (rank up 2)
            // Third foundation sequence: 3, 6, 9, Q, ..., K (rank up 3)
            // Fourth foundation sequence: 4, 8, Q, 3, ..., K (rank up 4)
            BuildupRankAbove(gap: i + 1, wrapping: true),
          ],
        ),
      );
    }

    return setup;
  }
}
