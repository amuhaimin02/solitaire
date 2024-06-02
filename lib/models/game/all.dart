import 'freecell.dart';
import 'klondike.dart';

final solitaireGamesList = [
  for (final scoring in KlondikeScoring.values)
    for (final draws in [1, 3])
      Klondike(numberOfDraws: draws, scoring: scoring),
  const FreeCell(),
];
