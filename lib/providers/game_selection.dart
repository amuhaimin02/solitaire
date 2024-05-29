import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/game/all.dart';
import '../models/game/solitaire.dart';
import '../services/shared_preferences.dart';
import 'game_storage.dart';

part 'game_selection.g.dart';

@riverpod
List<SolitaireGame> allSolitaireGames(AllSolitaireGamesRef ref) {
  return solitaireGamesList;
}

@riverpod
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

@riverpod
class SelectedGame extends _$SelectedGame {
  @override
  SolitaireGame build() => ref.watch(allSolitaireGamesProvider).first;

  void select(SolitaireGame newGame) => state = newGame;
}

@riverpod
List<SolitaireGame> selectedGameAlternateVariants(
    SelectedGameAlternateVariantsRef ref) {
  final selectedGame = ref.watch(selectedGameProvider);
  final allGamesMapped = ref.watch(allSolitaireGamesMappedProvider);

  return allGamesMapped[selectedGame.name]!;
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

@riverpod
List<SolitaireGame> continuableGames(ContinuableGamesRef ref) {
  final saveFiles = ref.watch(gameStorageProvider.notifier).getAllSaveFiles();
  return ref
      .watch(allSolitaireGamesProvider)
      .where((game) => saveFiles.contains(quickSaveFileName(game)))
      .toList();
}
