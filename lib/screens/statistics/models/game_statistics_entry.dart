import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_statistics_entry.freezed.dart';

@freezed
class GameStatisticsEntry with _$GameStatisticsEntry {
  factory GameStatisticsEntry({
    required DateTime startedTime,
    required Duration playTime,
    required String randomSeed,
    required int moves,
    required int score,
    required bool isSolved,
  }) = _GameStatisticsEntry;
}
