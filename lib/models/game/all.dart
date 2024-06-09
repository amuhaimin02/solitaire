import 'forty_thieves.dart';
import 'freecell.dart';
import 'golf.dart';
import 'klondike.dart';
import 'penguin.dart';
import 'spider.dart';
import 'yukon.dart';

const allGamesList = [
  Klondike(numberOfDraws: 1, vegasScoring: false),
  Klondike(numberOfDraws: 3, vegasScoring: false),
  Klondike(numberOfDraws: 1, vegasScoring: true),
  Klondike(numberOfDraws: 3, vegasScoring: true),
  FreeCell(),
  Penguin(),
  Spider(numberOfSuits: 1),
  Spider(numberOfSuits: 2),
  Spider(numberOfSuits: 4),
  Golf(),
  Yukon(),
  FortyThieves(),
];
