import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/game/solitaire.dart';
import '../models/play_data.dart';
import '../services/all.dart';
import '../services/file_handler.dart';
import '../services/game_serializer.dart';
import '../utils/compress.dart';
import '../utils/types.dart';
import 'file_handler.dart';
import 'game_selection.dart';

part 'game_storage.g.dart';

const saveFileExtension = 'solitairesave';

String quickSaveFileName(SolitaireGame game) =>
    'continue-${game.tag}.$saveFileExtension';

String exportFileName(SolitaireGame game) =>
    '${game.tag}-${DateTime.now().toPathFriendlyString()}.$saveFileExtension';

@riverpod
class GameStorage extends _$GameStorage {
  @override
  DateTime build() => DateTime.now();

  Future<List<int>> _convertToBytes(GameData gameData) async {
    final saveData = services<GameDataSerializer>().serialize(gameData);
    final compressedSaveData = await compressText(saveData);
    return compressedSaveData;
  }

  Future<GameData> _convertFromBytes(List<int> bytes) async {
    final decompressedSaveData = await decompressText(bytes);
    return services<GameDataSerializer>().deserialize(decompressedSaveData);
  }

  Future<void> quickSave(GameData gameData) async {
    final fileHandler = services<FileHandler>();
    final bytes = await _convertToBytes(gameData);

    fileHandler.save(quickSaveFileName(gameData.metadata.game), bytes);
    ref.invalidateSelf();
  }

  Future<GameData> restoreQuickSave(SolitaireGame game) async {
    final fileHandler = services<FileHandler>();
    final saveData = await fileHandler.load(quickSaveFileName(game));

    return _convertFromBytes(saveData);
  }

  Future<void> deleteQuickSave(SolitaireGame game) async {
    final fileHandler = services<FileHandler>();
    await fileHandler.remove(quickSaveFileName(game));
    ref.invalidateSelf();
  }

  Future<void> exportQuickSave(GameData gameData) async {
    final bytes = await _convertToBytes(gameData);

    final outputFilePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Choose where to export save file',
      fileName: exportFileName(gameData.metadata.game),
      type: FileType.any,
      bytes: Uint8List.fromList(bytes),
    );

    if (outputFilePath != null &&
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      File(outputFilePath).writeAsBytesSync(bytes);
    }
  }

  Future<GameData?> importQuickSave() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Choose save file to import',
      type: FileType.any,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      return _convertFromBytes(result.files.single.bytes!.toList());
    }
    return null;
  }
}

@riverpod
Future<List<SolitaireGame>> continuableGames(ContinuableGamesRef ref) async {
  ref.watch(gameStorageProvider);
  final fileHandler = services<FileHandler>();
  final saveFiles = await fileHandler.list('');
  final allGames = ref.watch(allSolitaireGamesProvider);
  return saveFiles
      .map((file) =>
          allGames.firstWhereOrNull((game) => quickSaveFileName(game) == file))
      .whereNotNull()
      .toList();
}
