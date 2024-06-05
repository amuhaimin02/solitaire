import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/game/solitaire.dart';
import '../models/play_data.dart';
import '../services/game_serializer.dart';
import '../utils/compress.dart';
import 'file_handler.dart';
import 'game_selection.dart';

part 'game_storage.g.dart';

const saveFileExtension = '.save';

String quickSaveFileName(SolitaireGame game) =>
    'continue-${game.tag}$saveFileExtension';

@riverpod
class GameStorage extends _$GameStorage {
  @override
  DateTime build() => DateTime.now();

  Future<void> quickSave(GameData gameData) async {
    final saveData = const GameDataSerializer().serialize(gameData);
    final compressedSaveData = await compressText(saveData);

    final fileHandler = ref.read(fileHandlerProvider.notifier);

    print(
        'Stored ${saveData.length} bytes of save data (compressed: ${compressedSaveData.length} bytes)');

    fileHandler.save(
        quickSaveFileName(gameData.metadata.game), compressedSaveData);
    ref.invalidateSelf();
  }

  Future<GameData> restoreQuickSave(SolitaireGame game) async {
    final fileHandler = ref.read(fileHandlerProvider.notifier);
    final saveData =
        await decompressText(await fileHandler.load(quickSaveFileName(game)));

    return const GameDataSerializer().deserialize(saveData);
  }

  Future<void> deleteQuickSave(SolitaireGame game) async {
    final fileHandler = ref.read(fileHandlerProvider.notifier);
    await fileHandler.remove(quickSaveFileName(game));
    ref.invalidateSelf();
  }
}

@riverpod
Future<List<SolitaireGame>> continuableGames(ContinuableGamesRef ref) async {
  ref.watch(gameStorageProvider);
  final saveFiles = await ref.read(fileHandlerProvider.notifier).list('');
  return ref
      .watch(allSolitaireGamesProvider)
      .where((game) => saveFiles.contains(quickSaveFileName(game)))
      .toList();
}
