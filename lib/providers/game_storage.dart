import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/play_data.dart';
import '../services/game_serializer.dart';
import '../utils/compress.dart';
import 'file_handler.dart';

part 'game_storage.g.dart';

// const saveFileExtension = '.save';
//
// String quickSaveFileName(SolitaireGame game) =>
//     'continue-${game.tag}$saveFileExtension';

const quickSaveFileName = 'continue.save';

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

    fileHandler.save(quickSaveFileName, compressedSaveData);
    ref.invalidateSelf();
  }

  Future<GameData> restoreQuickSave() async {
    final fileHandler = ref.read(fileHandlerProvider.notifier);
    final saveData =
        await decompressText(await fileHandler.load(quickSaveFileName));

    return const GameDataSerializer().deserialize(saveData);
  }

  Future<void> deleteQuickSave() async {
    final fileHandler = ref.read(fileHandlerProvider.notifier);
    await fileHandler.remove(quickSaveFileName);
    ref.invalidateSelf();
  }

  Future<bool> hasQuickSave() async {
    final fileHandler = ref.read(fileHandlerProvider.notifier);
    return fileHandler.exists(quickSaveFileName);
  }
}
