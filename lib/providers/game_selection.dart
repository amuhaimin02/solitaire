import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game/all.dart';
import '../models/game/solitaire.dart';
import '../services/all.dart';
import '../utils/types.dart';

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
    final prefs = svc<SharedPreferences>();
    final favoritedTags = prefs.getStringList(preferenceKey) ?? [];

    final allGamesMapped =
        ref.watch(allSolitaireGamesProvider).mapBy((game) => game.tag);

    // Ensure recently favorited one is on top
    return favoritedTags
        .map((tag) => allGamesMapped[tag])
        .whereNotNull()
        .toList()
        .reversed
        .toList();
  }

  void addToFavorite(SolitaireGame game) {
    final prefs = svc<SharedPreferences>();
    final favoritedTags = prefs.getStringList(preferenceKey) ?? [];
    prefs.setStringList(preferenceKey, [...favoritedTags, game.tag]);
    ref.invalidateSelf();
  }

  void removeFromFavorite(SolitaireGame game) {
    final prefs = svc<SharedPreferences>();
    final favoritedTags = prefs.getStringList(preferenceKey) ?? [];
    prefs.setStringList(preferenceKey,
        favoritedTags.whereNot((tag) => tag == game.tag).toList());
    ref.invalidateSelf();
  }
}
