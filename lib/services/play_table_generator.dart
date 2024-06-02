import '../models/game/solitaire.dart';
import '../models/pile_action.dart';
import '../models/play_data.dart';
import '../models/play_table.dart';

class PlayTableGenerator {
  static PlayTable generateSampleSetup(SolitaireGame game) {
    final sampleMetadata = GameMetadata(
      game: game,
      startedTime: DateTime.now(),
      randomSeed: '1',
    );

    PlayTable table = PlayTable.fromGame(game);

    for (final item in game.piles.entries) {
      final result =
          PileAction.run(item.value.onStart, item.key, table, sampleMetadata);
      if (result is PileActionSuccess) {
        table = result.table;
      }
    }
    for (final item in game.piles.entries) {
      final result =
          PileAction.run(item.value.onSetup, item.key, table, sampleMetadata);
      if (result is PileActionSuccess) {
        table = result.table;
      }
    }
    return table;
  }
}
