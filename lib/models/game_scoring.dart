import 'move_event.dart';
import 'move_record.dart';

class GameScoring {
  final int Function(MoveEvent event) determineScore;

  final int Function(Duration playTime, MoveState state)? bonusOnFinish;

  final int Function(Duration playTime, MoveState state)? penaltyOnFinish;

  final int startingScore;

  final bool vegasScoring;

  const GameScoring({
    required this.determineScore,
    this.bonusOnFinish,
    this.penaltyOnFinish,
    this.startingScore = 0,
    this.vegasScoring = false,
  });

  GameScoreSummary getScoreSummary({
    required Duration playTime,
    required MoveState moveState,
  }) {
    return GameScoreSummary(
        playTime: playTime, scoring: this, moveState: moveState);
  }
}

class GameScoreSummary {
  GameScoreSummary({
    required this.playTime,
    required this.scoring,
    required this.moveState,
  });

  final Duration playTime;

  final GameScoring scoring;

  final MoveState moveState;

  int get moves => moveState.moveNumber;

  int get obtainedScore => moveState.score;

  bool get hasBonus => scoring.bonusOnFinish != null;

  bool get hasPenalty => scoring.penaltyOnFinish != null;

  int get bonusScore {
    if (hasBonus) {
      return scoring.bonusOnFinish!(playTime, moveState);
    } else {
      return 0;
    }
  }

  int get penaltyScore {
    if (hasPenalty) {
      return scoring.penaltyOnFinish!(playTime, moveState);
    } else {
      return 0;
    }
  }

  int get finalScore => obtainedScore + bonusScore - penaltyScore;
}
