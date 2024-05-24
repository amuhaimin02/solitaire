import '../game_state.dart';
import '../rules/rules.dart';
import '../states/game.dart';

class GameplayStorage {
  void save(List<MoveRecord> history, SolitaireGame rules) {
    final tag = _getGameTag(rules);
    print('saving ${history.length} to $tag');
  }

  String _getGameTag(SolitaireGame rules) {
    if (rules.hasVariants) {
      return "${rules.tag}:${rules.variant.tag}";
    } else {
      return rules.tag;
    }
  }
}
