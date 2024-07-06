import 'impl/aces_up.dart';
import 'impl/calculation.dart';
import 'impl/canfield.dart';
import 'impl/eight_off.dart';
import 'impl/forty_thieves.dart';
import 'impl/freecell.dart';
import 'impl/golf.dart';
import 'impl/grandfathers_clock.dart';
import 'impl/klondike.dart';
import 'impl/klondike_vegas.dart';
import 'impl/maze.dart';
import 'impl/penguin.dart';
import 'impl/putt_putt.dart';
import 'impl/pyramid.dart';
import 'impl/scorpion.dart';
import 'impl/simple_simon.dart';
import 'impl/sir_tommy.dart';
import 'impl/spider.dart';
import 'impl/spiderette.dart';
import 'impl/tower_of_hanoy.dart';
import 'impl/tripeaks.dart';
import 'impl/yukon.dart';

final allGamesList = [
  Klondike(numberOfDraws: 1),
  Klondike(numberOfDraws: 3),
  KlondikeVegas(numberOfDraws: 1),
  KlondikeVegas(numberOfDraws: 3),
  FreeCell(),
  EightOff(),
  Penguin(),
  Spider(numberOfSuits: 1),
  Spider(numberOfSuits: 2),
  Spider(numberOfSuits: 4),
  Spiderette(numberOfSuits: 1),
  Spiderette(numberOfSuits: 2),
  Spiderette(numberOfSuits: 4),
  SimpleSimon(),
  Scorpion(),
  Canfield(numberOfDraws: 1),
  Canfield(numberOfDraws: 3),
  Golf(),
  PuttPutt(),
  Yukon(),
  FortyThieves(),
  Pyramid(),
  SirTommy(),
  Calculation(),
  AcesUp(),
  Maze(),
  TriPeaks(),
  TowerOfHanoy(),
  GrandfathersClock(),
];
