import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game/solitaire.dart';
import '../services/all.dart';
import '../utils/types.dart';
import 'game_logic.dart';
import 'game_move_history.dart';
import 'game_selection.dart';

part 'statistics.g.dart';

const _statisticsPrefix = 'stats';
const _statisticsPlaytimeSuffix = 'playtime';
const _statisticsGameCountSuffix = 'games';
const _statisticsWinCountSuffix = 'won';

String _getPrefsKey(SolitaireGame game, String suffix) {
  return '${_statisticsPrefix}_${game.tag}_$suffix';
}

@riverpod
class StatisticsUpdater extends _$StatisticsUpdater {
  @override
  void build() {}

  Future<void> recordCurrentGame() async {
    final game = ref.read(currentGameProvider);
    final playTime = ref.read(playTimeProvider);
    final moves = ref.read(currentMoveProvider);
    final isFinished = ref.read(isGameFinishedProvider);

    await _updateOverallStatistics(
      game: game.kind,
      playTime: playTime,
      isFinished: isFinished,
    );

    await _updateGameStatistics(
      game: game.kind,
      playTime: playTime,
      moves: moves?.state.moveNumber ?? 0,
      score: moves?.state.score ?? 0,
      isFinished: isFinished,
    );

    ref.invalidateSelf();
  }

  Future<void> _updateOverallStatistics({
    required SolitaireGame game,
    required Duration playTime,
    required bool isFinished,
  }) async {
    final prefs = svc<SharedPreferences>();

    _incrementAndUpdate(
      prefs,
      _getPrefsKey(game, _statisticsPlaytimeSuffix),
      playTime.inMilliseconds,
    );
    _incrementAndUpdate(
      prefs,
      _getPrefsKey(game, _statisticsGameCountSuffix),
      1,
    );
    if (isFinished) {
      _incrementAndUpdate(
        prefs,
        _getPrefsKey(game, _statisticsWinCountSuffix),
        1,
      );
    }
  }

  Future<void> _updateGameStatistics({
    required SolitaireGame game,
    required Duration playTime,
    required int moves,
    required int score,
    required bool isFinished,
  }) async {}

  void _incrementAndUpdate(SharedPreferences prefs, String key, int value) {
    final currentValue = prefs.getInt(key) ?? 0;
    prefs.setInt(key, currentValue + value);
  }
}

@riverpod
Duration statisticsPlayTime(
    StatisticsTotalPlayTimeRef ref, SolitaireGame game) {
  final prefs = svc<SharedPreferences>();
  return Duration(
      milliseconds:
          prefs.getInt(_getPrefsKey(game, _statisticsPlaytimeSuffix)) ?? 0);
}

@riverpod
Duration statisticsTotalPlayTime(StatisticsTotalPlayTimeRef ref) {
  return ref.watch(allSolitaireGamesProvider).fold(
        Duration.zero,
        (total, game) => total + ref.watch(statisticsPlayTimeProvider(game)),
      );
}

@riverpod
int statisticsGamesPlayed(StatisticsGamesPlayedRef ref, SolitaireGame game) {
  final prefs = svc<SharedPreferences>();
  return prefs.getInt(_getPrefsKey(game, _statisticsGameCountSuffix)) ?? 0;
}

@riverpod
int statisticsTotalGamesPlayed(StatisticsTotalGamesPlayedRef ref) {
  return ref
      .watch(allSolitaireGamesProvider)
      .map((game) => ref.watch(statisticsGamesPlayedProvider(game)))
      .sum;
}

@riverpod
int statisticsGamesWon(StatisticsGamesWonRef ref, SolitaireGame game) {
  final prefs = svc<SharedPreferences>();
  return prefs.getInt(_getPrefsKey(game, _statisticsWinCountSuffix)) ?? 0;
}

@riverpod
int statisticsTotalGamesWon(StatisticsTotalGamesWonRef ref) {
  return ref
      .watch(allSolitaireGamesProvider)
      .map((game) => ref.watch(statisticsGamesWonProvider(game)))
      .sum;
}

@riverpod
int statisticsTotalGameTypesPlayed(StatisticsTotalGameTypesPlayedRef ref) {
  return ref
      .watch(allSolitaireGamesProvider)
      .map((game) => ref.watch(statisticsGamesPlayedProvider(game)))
      .count((totalGames) => totalGames > 0);
}

@riverpod
int statisticsTotalGameTypesWon(StatisticsTotalGameTypesWonRef ref) {
  return ref
      .watch(allSolitaireGamesProvider)
      .map((game) => ref.watch(statisticsGamesWonProvider(game)))
      .count((totalWins) => totalWins > 0);
}
