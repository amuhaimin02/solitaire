import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/game/klondike.dart';
import '../models/game/simple.dart';
import '../models/game/solitaire.dart';

part 'game_selection.g.dart';

@riverpod
List<SolitaireGame> allSolitaireGames(AllSolitaireGamesRef ref) {
  return [
    for (final scoring in KlondikeScoring.values)
      for (final draws in KlondikeDraws.values)
        Klondike(
          KlondikeVariant(draws: draws, scoring: scoring),
        ),
    SimpleSolitaire(),
  ];
}

@riverpod
Map<String, List<SolitaireGame>> allSolitaireGamesMapped(
    AllSolitaireGamesMappedRef ref) {
  final allGames = ref.watch(allSolitaireGamesProvider);
  return groupBy(allGames, (rules) => rules.name);
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
