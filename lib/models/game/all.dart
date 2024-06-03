import 'freecell.dart';
import 'klondike.dart';

const solitaireGamesList = [
  Klondike(numberOfDraws: 1, vegasScoring: false),
  Klondike(numberOfDraws: 3, vegasScoring: false),
  Klondike(numberOfDraws: 1, vegasScoring: true),
  Klondike(numberOfDraws: 3, vegasScoring: true),
  FreeCell(),
];
