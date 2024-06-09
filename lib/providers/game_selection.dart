import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/game/all.dart';
import '../models/game/solitaire.dart';
import '../services/shared_preferences.dart';

part 'game_selection.g.dart';

@Riverpod(keepAlive: true)
List<SolitaireGame> allSolitaireGames(AllSolitaireGamesRef ref) {
  return allGamesList;
}

@Riverpod(keepAlive: true)
Map<String, List<SolitaireGame>> allSolitaireGamesMapped(
    AllSolitaireGamesMappedRef ref) {
  return groupBy(ref.watch(allSolitaireGamesProvider), (rules) => rules.family);
}

@riverpod
class GameSelectionDropdown extends _$GameSelectionDropdown {
  @override
  bool build() => false;

  void open() => state = true;

  void close() => state = false;
}

@Riverpod(keepAlive: true)
class SelectedGame extends _$SelectedGame {
  @override
  SolitaireGame? build() => null;

  void select(SolitaireGame newGame) => state = newGame;

  void deselect() => state = null;
}

@riverpod
class FavoritedGames extends _$FavoritedGames {
  static const preferenceKey = 'favorite';
  @override
  List<SolitaireGame> build() {
    final prefs = ref.read(sharedPreferencesInstanceProvider);
    if (prefs == null) {
      return [];
    }
    final favoritedTags = prefs.getStringList(preferenceKey) ?? [];
    return ref
        .watch(allSolitaireGamesProvider)
        .where((game) => favoritedTags.contains(game.tag))
        .toList();
  }

  void addToFavorite(SolitaireGame game) {
    final prefs = ref.read(sharedPreferencesInstanceProvider);
    if (prefs == null) {
      return;
    }
    final favoritedTags = prefs.getStringList(preferenceKey) ?? [];
    prefs.setStringList(preferenceKey, [...favoritedTags, game.tag]);
    ref.invalidateSelf();
  }

  void removeFromFavorite(SolitaireGame game) {
    final prefs = ref.read(sharedPreferencesInstanceProvider);
    if (prefs == null) {
      return;
    }
    final favoritedTags = prefs.getStringList(preferenceKey) ?? [];
    prefs.setStringList(preferenceKey,
        favoritedTags.whereNot((tag) => tag == game.tag).toList());
    ref.invalidateSelf();
  }
}
