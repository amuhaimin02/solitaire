import 'klondike.dart';
import 'simple.dart';

final allSolitaireGames = [
  for (final scoring in KlondikeScoring.values)
    for (final draws in KlondikeDraws.values)
      Klondike(
        KlondikeVariant(draws: draws, scoring: scoring),
      ),
  const SimpleSolitaire(),
];
