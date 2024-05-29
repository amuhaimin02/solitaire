import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_handler.g.dart';

@Riverpod(keepAlive: true)
Future<Directory> appDataDirectoryFuture(AppDataDirectoryFutureRef ref) async {
  return await getApplicationDocumentsDirectory();
}

@riverpod
Directory? appDataDirectory(AppDataDirectoryRef ref) {
  return ref.watch(appDataDirectoryFutureProvider).value;
}

@riverpod
class FileHandler extends _$FileHandler {
  @override
  void build() {}

  void save(String filePath, List<int> fileData) {
    final baseDir = ref.read(appDataDirectoryProvider);
    if (baseDir == null) return;
    final targetFile = File('${baseDir.path}/$filePath');
    targetFile.writeAsBytesSync(fileData);
  }

  List<int> load(String filePath) {
    final baseDir = ref.read(appDataDirectoryProvider);
    if (baseDir == null) throw StateError('Cannot load base directory path');
    final targetFile = File('${baseDir.path}/$filePath');
    return targetFile.readAsBytesSync();
  }

  bool exists(String filePath) {
    final baseDir = ref.read(appDataDirectoryProvider);
    if (baseDir == null) return false;
    final targetFile = File('${baseDir.path}/$filePath');
    return targetFile.existsSync();
  }

  void remove(String filePath) {
    final baseDir = ref.read(appDataDirectoryProvider);
    if (baseDir == null) return;
    final targetFile = File('${baseDir.path}/$filePath');
    if (targetFile.existsSync()) {
      targetFile.deleteSync();
    }
  }

  List<String> listFiles(String path) {
    final baseDir = ref.read(appDataDirectoryProvider);
    if (baseDir == null) return [];
    return Directory('${baseDir.path}/$path')
        .listSync()
        .map((entity) => basename(entity.path))
        .toList();
  }
}
