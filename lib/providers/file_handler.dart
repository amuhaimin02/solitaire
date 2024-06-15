// import 'dart:io';
//
// import 'package:collection/collection.dart';
// import 'package:path/path.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:riverpod_annotation/riverpod_annotation.dart';
//
// part 'file_handler.g.dart';
//
// @Riverpod(keepAlive: true)
// Future<Directory> appDataDirectory(AppDataDirectoryRef ref) async {
//   return await getApplicationDocumentsDirectory();
// }
//
// @riverpod
// class FileHandler extends _$FileHandler {
//   @override
//   void build() {}
//
//   Future<void> save(String filePath, List<int> fileData) async {
//     final baseDir = await ref.read(appDataDirectoryProvider.future);
//     final targetFile = File('${baseDir.path}/$filePath');
//     targetFile.writeAsBytesSync(fileData);
//   }
//
//   Future<List<int>> load(String filePath) async {
//     final baseDir = await ref.read(appDataDirectoryProvider.future);
//     final targetFile = File('${baseDir.path}/$filePath');
//     return targetFile.readAsBytesSync();
//   }
//
//   Future<bool> exists(String filePath) async {
//     final baseDir = await ref.read(appDataDirectoryProvider.future);
//     final targetFile = File('${baseDir.path}/$filePath');
//     return targetFile.existsSync();
//   }
//
//   Future<void> remove(String filePath) async {
//     final baseDir = await ref.read(appDataDirectoryProvider.future);
//     final targetFile = File('${baseDir.path}/$filePath');
//     if (targetFile.existsSync()) {
//       targetFile.deleteSync();
//     }
//   }
//
//   Future<List<String>> list(String path) async {
//     final baseDir = await ref.read(appDataDirectoryProvider.future);
//     return Directory('${baseDir.path}/$path')
//         .listSync()
//         .sortedBy((file) => file.statSync().modified)
//         .reversed
//         .map((file) => basename(file.path))
//         .toList();
//   }
// }
