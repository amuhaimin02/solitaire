/// https://en.wikipedia.org/wiki/Klondike_(solitaire)#Computerized_versions
class ScoreSummary {
  ScoreSummary(
      {required this.playTime,
      required this.moves,
      required this.obtainedScore});

  final Duration playTime;

  final int obtainedScore;

  final int moves;

  int get bonusScore {
    if (playTime > const Duration(seconds: 30)) {
      return 700000 ~/ playTime.inSeconds;
    } else {
      return 0;
    }
  }

  int get penaltyScore {
    if (playTime > const Duration(seconds: 10)) {
      return (playTime.inSeconds ~/ 10) * 2;
    } else {
      return 0;
    }
  }

  int get finalScore => obtainedScore + bonusScore - penaltyScore;
}
