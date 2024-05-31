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
      if (pile.onStart != null) {
        table = PileAction.runAll(
          originTable: table,
          actions: pile.onStart!,
          pile: pile.kind,
          metadata: sampleMetadata,
        );
      }
    }
    for (final pile in game.piles) {
      if (pile.onSetup != null) {
        table = PileAction.runAll(
          originTable: table,
          actions: pile.onSetup!,
          pile: pile.kind,
          metadata: sampleMetadata,
        );
      }
    }
    return table;
  }
}
