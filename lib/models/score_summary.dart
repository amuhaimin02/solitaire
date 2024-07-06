import 'game_scoring.dart';
import 'move_record.dart';

/// https://en.wikipedia.org/wiki/Klondike_(solitaire)#Computerized_versions
class ScoreSummary {
  ScoreSummary({
    required this.playTime,
    required this.scoring,
    required this.moveState,
  });

  final Duration playTime;

  final GameScoring? scoring;

  final MoveState moveState;

  int get moves => moveState.moveNumber;

  int get obtainedScore => moveState.score;

  bool get hasBonus => scoring?.bonusOnFinish != null;

  bool get hasPenalty => scoring?.penaltyOnFinish != null;

  int get bonusScore {
    if (hasBonus) {
      return scoring!.bonusOnFinish!(playTime, moveState);
    } else {
      return 0;
    }
  }

  int get penaltyScore {
    if (hasPenalty) {
      return scoring!.penaltyOnFinish!(playTime, moveState);
    } else {
      return 0;
    }
  }

  int get finalScore => obtainedScore + bonusScore - penaltyScore;
}
