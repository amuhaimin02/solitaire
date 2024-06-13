import 'impl/canfield.dart';
import 'impl/forty_thieves.dart';
import 'impl/freecell.dart';
import 'impl/golf.dart';
import 'impl/klondike.dart';
import 'impl/penguin.dart';
import 'impl/putt_putt.dart';
import 'impl/pyramid.dart';
import 'impl/spider.dart';
import 'impl/tripeaks.dart';
import 'impl/yukon.dart';

final allGamesList = [
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
  PuttPutt(),
  Yukon(),
  FortyThieves(),
  Canfield(numberOfDraws: 1),
  Canfield(numberOfDraws: 3),
  Pyramid(),
  TriPeaks(),
];
