import 'freecell.dart';
import 'klondike.dart';
import 'spider.dart';

const solitaireGamesList = [
  Klondike(numberOfDraws: 1, vegasScoring: false),
  Klondike(numberOfDraws: 3, vegasScoring: false),
  Klondike(numberOfDraws: 1, vegasScoring: true),
  Klondike(numberOfDraws: 3, vegasScoring: true),
  FreeCell(),
  Spider(numberOfSuits: 1),
  Spider(numberOfSuits: 2),
  Spider(numberOfSuits: 4),
];
