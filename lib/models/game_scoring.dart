import 'move_event.dart';
import 'move_record.dart';

class GameScoring {
  final int Function(MoveEvent event) determineScore;

  final int Function(Duration playTime, MoveState state)? bonusOnFinish;

  final int Function(Duration playTime, MoveState state)? penaltyOnFinish;

  GameScoring({
    required this.determineScore,
    this.bonusOnFinish,
    this.penaltyOnFinish,
  });
}
