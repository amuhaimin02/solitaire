import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/game/solitaire.dart';
import '../models/play_data.dart';
import '../services/game_serializer.dart';
import '../utils/compress.dart';
import 'file_handler.dart';

part 'game_storage.g.dart';

String _quickSaveFileName(SolitaireGame game) => 'continue-${game.fullTag}';

@riverpod
class GameStorage extends _$GameStorage {
  @override
  DateTime build() => DateTime.now();

  Future<void> quickSave(GameData gameData) async {
    final game = gameData.metadata.rules;

    final saveData = const GameDataSerializer().serialize(gameData);
    final compressedSaveData = await compressText(saveData);

    final fileHandler = ref.read(fileHandlerProvider.notifier);

    print(
        'Stored ${saveData.length} bytes of save data (compressed: ${compressedSaveData.length} bytes)');

    fileHandler.save(_quickSaveFileName(game), compressedSaveData);
    ref.invalidateSelf();
  }

  Future<GameData> restoreQuickSave(SolitaireGame game) async {
    final fileHandler = ref.read(fileHandlerProvider.notifier);
    final saveData =
        await decompressText(await fileHandler.load(_quickSaveFileName(game)));

    return const GameDataSerializer().deserialize(saveData);
  }

  Future<void> deleteQuickSave(SolitaireGame game) async {
    final fileHandler = ref.read(fileHandlerProvider.notifier);

    fileHandler.remove(_quickSaveFileName(game));
    ref.invalidateSelf();
  }
}

@riverpod
Future<bool> hasQuickSave(HasQuickSaveRef ref, SolitaireGame game) {
  ref.watch(gameStorageProvider);
  final fileHandler = ref.watch(fileHandlerProvider.notifier);
  return fileHandler.exists(_quickSaveFileName(game));
}
