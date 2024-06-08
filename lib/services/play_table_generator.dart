import '../models/game/solitaire.dart';
import '../models/move_record.dart';
import '../models/pile_action.dart';
import '../models/play_data.dart';
import '../models/play_table.dart';
import '../utils/types.dart';

class PlayTableGenerator {
  static PlayTable generateSampleSetup(SolitaireGame game, String randomSeed) {
    final sampleMetadata = GameMetadata(
      game: game,
      startedTime: DateTime.now(),
      randomSeed: randomSeed,
    );

    PlayTable table = PlayTable.fromGame(game);

    for (final (pile, props) in game.piles.items) {
      final result = PileAction.run(
        props.onStart,
        PileActionData(
          pile: pile,
          table: table,
          metadata: sampleMetadata,
        ),
      );
      if (result is PileActionHandled) {
        table = result.table;
      }
    }
    for (final (pile, props) in game.piles.items) {
      final result = PileAction.run(
        props.onSetup,
        PileActionData(
          pile: pile,
          table: table,
          metadata: sampleMetadata,
        ),
      );
      if (result is PileActionHandled) {
        table = result.table;
      }
    }
    return table;
  }
}
