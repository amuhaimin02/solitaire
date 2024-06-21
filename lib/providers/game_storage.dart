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
    final saveData = svc<GameDataSerializer>().serialize(gameData);
    final compressedSaveData = await compressText(saveData);
    return compressedSaveData;
  }

  Future<GameData> _convertFromBytes(List<int> bytes) async {
    final decompressedSaveData = await decompressText(bytes);
    return svc<GameDataSerializer>().deserialize(decompressedSaveData);
  }

  Future<void> quickSave(GameData gameData) async {
    final fileHandler = svc<FileHandler>();
    final bytes = await _convertToBytes(gameData);

    fileHandler.save(quickSaveFileName(gameData.metadata.kind), bytes);
    ref.invalidateSelf();
  }

  Future<GameData> restoreQuickSave(SolitaireGame game) async {
    final fileHandler = svc<FileHandler>();
    final saveData = await fileHandler.load(quickSaveFileName(game));

    return _convertFromBytes(saveData);
  }

  Future<void> deleteQuickSave(SolitaireGame game) async {
    final fileHandler = svc<FileHandler>();
    await fileHandler.remove(quickSaveFileName(game));
    ref.invalidateSelf();
  }

  Future<void> exportQuickSave(GameData gameData) async {
    final bytes = await _convertToBytes(gameData);

    final outputFilePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Choose where to export save file',
      fileName: exportFileName(gameData.metadata.kind),
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
  final fileHandler = svc<FileHandler>();
  final saveFiles = await fileHandler.list('');

  final allGamesMapped = ref
      .watch(allSolitaireGamesProvider)
      .mapBy((game) => quickSaveFileName(game));

  return saveFiles.map((file) => allGamesMapped[file]).whereNotNull().toList();
}
