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

    for (final pile in game.piles) {
      table = PileAction.runAll(pile.onStart, pile.kind, table, sampleMetadata);
    }
    for (final pile in game.piles) {
      table = PileAction.runAll(pile.onSetup, pile.kind, table, sampleMetadata);
    }
    return table;
  }
}
