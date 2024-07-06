import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:csv/csv.dart';

import '../models/game/solitaire.dart';
import '../screens/statistics/models/game_statistics_entry.dart';
import '../screens/statistics/models/statistics_display_mode.dart';
import '../services/all.dart';
import '../services/file_handler.dart';
import '../utils/compress.dart';
import '../utils/types.dart';
import 'game_logic.dart';
import 'game_move_history.dart';
import 'game_selection.dart';

part 'statistics.g.dart';

const _statisticsPrefix = 'stats';
const _statisticsPlaytimeSuffix = 'playtime';
const _statisticsGameCountSuffix = 'games';
const _statisticsWinCountSuffix = 'won';

const _statisticsFolder = 'stats';
const _statisticsFileExtension = 'solitairestats';
const _statisticsRecentFileSuffix = 'recent';
const _statisticsHighScoreFileSuffix = 'highscore';

const _statisticsRecentListLimit = 20;
const _statisticsHighScoreListLimit = 20;

String _getPrefsKey(SolitaireGame game, String suffix) {
  return '${_statisticsPrefix}_${game.tag}_$suffix';
}

String _gameStatisticsFilePath(SolitaireGame game, GameStatisticsType type) {
  final suffix = switch (type) {
    GameStatisticsType.highScore => _statisticsHighScoreFileSuffix,
    GameStatisticsType.recent => _statisticsRecentFileSuffix,
  };
  return '$_statisticsFolder/${game.tag}-$suffix.$_statisticsFileExtension';
}

@riverpod
class StatisticsUpdater extends _$StatisticsUpdater {
  @override
  DateTime build() => DateTime.now();

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
      entry: GameStatisticsEntry(
        startedTime: game.startedTime,
        randomSeed: game.seed,
        playTime: playTime,
        moves: moves?.state.moveNumber ?? 0,
        score: moves?.state.score ?? 0,
        isSolved: isFinished,
      ),
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
    required GameStatisticsEntry entry,
  }) async {
    // Store this game on recent list
    // The entry will be placed in the top of the list
    final recentList = await ref.read(
        statisticsForGameProvider(game, GameStatisticsType.recent).future);
    recentList.insert(0, entry);
    await _storeGameStatisticsFile(game, GameStatisticsType.recent,
        recentList.take(_statisticsRecentListLimit).toList());

    // Store this game on high score list
    // The entry will be placed in the suitable slot
    final highScoreList = await ref.read(
        statisticsForGameProvider(game, GameStatisticsType.highScore).future);
    highScoreList.add(entry);

    highScoreList.sort(game.scoring.lowerIsBetter
        ? (a, b) => a.score.compareTo(b.score)
        : (a, b) => b.score.compareTo(a.score));

    await _storeGameStatisticsFile(game, GameStatisticsType.highScore,
        highScoreList.take(_statisticsHighScoreListLimit).toList());
  }

  void _incrementAndUpdate(SharedPreferences prefs, String key, int value) {
    final currentValue = prefs.getInt(key) ?? 0;
    prefs.setInt(key, currentValue + value);
  }

  Future<void> _storeGameStatisticsFile(
    SolitaireGame game,
    GameStatisticsType type,
    List<GameStatisticsEntry> entries,
  ) async {
    const csvConverter = ListToCsvConverter();
    final csvString = csvConverter.convert(entries.map((entry) {
      return [
        entry.startedTime.toIso8601String(),
        entry.playTime.inMilliseconds,
        entry.randomSeed,
        entry.moves,
        entry.score,
        entry.isSolved ? 1 : 0,
      ];
    }).toList());
    final fileHandler = svc<FileHandler>();
    await fileHandler.save(
      _gameStatisticsFilePath(game, type),
      await compressText(csvString),
    );
  }

  Future<void> clearGameStatistics(SolitaireGame game) async {
    final prefs = svc<SharedPreferences>();

    prefs.remove(_getPrefsKey(game, _statisticsPlaytimeSuffix));
    prefs.remove(_getPrefsKey(game, _statisticsGameCountSuffix));
    prefs.remove(_getPrefsKey(game, _statisticsWinCountSuffix));

    final fileHandler = svc<FileHandler>();
    await fileHandler
        .remove(_gameStatisticsFilePath(game, GameStatisticsType.highScore));
    await fileHandler
        .remove(_gameStatisticsFilePath(game, GameStatisticsType.recent));

    ref.invalidateSelf();
  }
}

@riverpod
Duration statisticsPlayTime(
    StatisticsTotalPlayTimeRef ref, SolitaireGame game) {
  ref.watch(statisticsUpdaterProvider);

  final prefs = svc<SharedPreferences>();
  return Duration(
      milliseconds:
          prefs.getInt(_getPrefsKey(game, _statisticsPlaytimeSuffix)) ?? 0);
}

@riverpod
Duration statisticsTotalPlayTime(StatisticsTotalPlayTimeRef ref) {
  ref.watch(statisticsUpdaterProvider);

  return ref.watch(allSolitaireGamesProvider).fold(
        Duration.zero,
        (total, game) => total + ref.watch(statisticsPlayTimeProvider(game)),
      );
}

@riverpod
int statisticsGamesPlayed(StatisticsGamesPlayedRef ref, SolitaireGame game) {
  ref.watch(statisticsUpdaterProvider);

  final prefs = svc<SharedPreferences>();
  return prefs.getInt(_getPrefsKey(game, _statisticsGameCountSuffix)) ?? 0;
}

@riverpod
int statisticsTotalGamesPlayed(StatisticsTotalGamesPlayedRef ref) {
  ref.watch(statisticsUpdaterProvider);

  return ref
      .watch(allSolitaireGamesProvider)
      .map((game) => ref.watch(statisticsGamesPlayedProvider(game)))
      .sum;
}

@riverpod
int statisticsGamesWon(StatisticsGamesWonRef ref, SolitaireGame game) {
  ref.watch(statisticsUpdaterProvider);

  final prefs = svc<SharedPreferences>();
  return prefs.getInt(_getPrefsKey(game, _statisticsWinCountSuffix)) ?? 0;
}

@riverpod
int statisticsTotalGamesWon(StatisticsTotalGamesWonRef ref) {
  ref.watch(statisticsUpdaterProvider);

  return ref
      .watch(allSolitaireGamesProvider)
      .map((game) => ref.watch(statisticsGamesWonProvider(game)))
      .sum;
}

@riverpod
int statisticsTotalGameTypesPlayed(StatisticsTotalGameTypesPlayedRef ref) {
  ref.watch(statisticsUpdaterProvider);

  return ref
      .watch(allSolitaireGamesProvider)
      .map((game) => ref.watch(statisticsGamesPlayedProvider(game)))
      .count((totalGames) => totalGames > 0);
}

@riverpod
int statisticsTotalGameTypesWon(StatisticsTotalGameTypesWonRef ref) {
  ref.watch(statisticsUpdaterProvider);

  return ref
      .watch(allSolitaireGamesProvider)
      .map((game) => ref.watch(statisticsGamesWonProvider(game)))
      .count((totalWins) => totalWins > 0);
}

@riverpod
Future<List<GameStatisticsEntry>> statisticsForGame(StatisticsForGameRef ref,
    SolitaireGame game, GameStatisticsType type) async {
  ref.watch(statisticsUpdaterProvider);

  final fileHandler = svc<FileHandler>();

  final filePath = _gameStatisticsFilePath(game, type);

  if (!await fileHandler.exists(filePath)) {
    return [];
  }

  final rawData = await fileHandler.load(filePath);
  final csvString = await decompressText(rawData);
  const csvConverter = CsvToListConverter();
  final entries = csvConverter.convert(csvString);
  return entries.map((entry) {
    return GameStatisticsEntry(
      startedTime: DateTime.parse(entry[0] as String),
      playTime: Duration(milliseconds: entry[1] as int),
      randomSeed: entry[2] as String,
      moves: entry[3] as int,
      score: entry[4] as int,
      isSolved: entry[5] == 1,
    );
  }).toList();
}
