import 'move_event.dart';
import 'move_record.dart';
import 'play_table.dart';

class GameScoring {
  final int Function(MoveEvent event) determineScore;

  final int Function(Duration playTime, PlayTable table, MoveState state)?
      bonusOnFinish;

  final int Function(Duration playTime, PlayTable table, MoveState state)?
      penaltyOnFinish;

  final int startingScore;

  final bool vegasScoring;

  final bool lowerIsBetter;

  const GameScoring({
    required this.determineScore,
    this.bonusOnFinish,
    this.penaltyOnFinish,
    this.startingScore = 0,
    this.vegasScoring = false,
    this.lowerIsBetter = false,
  });

  GameScoreSummary getScoreSummary({
    required Duration playTime,
    required PlayTable table,
    required MoveState moveState,
  }) {
    return GameScoreSummary(
      playTime: playTime,
      scoring: this,
      table: table,
      moveState: moveState,
    );
  }
}

class GameScoreSummary {
  GameScoreSummary({
    required this.playTime,
    required this.scoring,
    required this.table,
    required this.moveState,
  });

  final Duration playTime;

  final GameScoring scoring;

  final PlayTable table;

  final MoveState moveState;

  int get moves => moveState.moveNumber;

  int get obtainedScore => moveState.score;

  bool get hasBonus => scoring.bonusOnFinish != null;

  bool get hasPenalty => scoring.penaltyOnFinish != null;

  int get bonusScore {
    if (hasBonus) {
      return scoring.bonusOnFinish!(playTime, table, moveState);
    } else {
      return 0;
    }
  }

  int get penaltyScore {
    if (hasPenalty) {
      return scoring.penaltyOnFinish!(playTime, table, moveState);
    } else {
      return 0;
    }
  }

  int get finalScore => obtainedScore + bonusScore - penaltyScore;
}
