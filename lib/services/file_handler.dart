import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'all.dart';
import 'save_directory.dart';

class FileHandlerException implements Exception {
  const FileHandlerException(this.message);

  final String message;

  @override
  String toString() => 'FileHandlerException: $message';
}

abstract class FileHandler {
  Future<void> save(String filePath, List<int> fileData);

  Future<List<int>> load(String filePath);

  Future<bool> exists(String filePath);

  Future<void> remove(String filePath);

  Future<List<String>> list(String path);
}

class StandardFileHandler extends FileHandler {
  @override
  Future<void> save(String filePath, List<int> fileData) async {
    final baseDir = svc<SaveDirectory>();
    final targetFile = File('${baseDir.path}/$filePath');
    targetFile.createSync(recursive: true);
    targetFile.writeAsBytesSync(fileData);
  }

  @override
  Future<List<int>> load(String filePath) async {
    final baseDir = svc<SaveDirectory>();
    final targetFile = File('${baseDir.path}/$filePath');
    return targetFile.readAsBytesSync();
  }

  @override
  Future<bool> exists(String filePath) async {
    final baseDir = svc<SaveDirectory>();
    final targetFile = File('${baseDir.path}/$filePath');
    return targetFile.existsSync();
  }

  @override
  Future<void> remove(String filePath) async {
    final baseDir = svc<SaveDirectory>();
    final targetFile = File('${baseDir.path}/$filePath');
    if (targetFile.existsSync()) {
      targetFile.deleteSync();
    }
  }

  @override
  Future<List<String>> list(String path) async {
    final baseDir = svc<SaveDirectory>();
    return Directory('${baseDir.path}/$path')
        .listSync()
        .sortedBy((file) => file.statSync().modified)
        .reversed
        .map((file) => basename(file.path))
        .toList();
  }
}

class WebFileHandler extends FileHandler {
  static const _prefsKeyPrefix = 'storage_';

  @override
  Future<bool> exists(String filePath) async {
    final prefs = svc<SharedPreferences>();
    return prefs.containsKey('$_prefsKeyPrefix$filePath');
  }

  @override
  Future<List<String>> list(String path) async {
    final prefs = svc<SharedPreferences>();
    final storedFiles = prefs
        .getKeys()
        .where((key) => key.startsWith(_prefsKeyPrefix))
        .map((key) => key.substring(_prefsKeyPrefix.length)) // Remove prefix
        .toList();
    return storedFiles;
  }

  @override
  Future<List<int>> load(String filePath) async {
    final prefs = svc<SharedPreferences>();
    final storedData = prefs.getString('$_prefsKeyPrefix$filePath');
    if (storedData == null) {
      throw const FileHandlerException('File not found or cannot be loaded');
    }
    return base64Decode(storedData);
  }

  @override
  Future<void> remove(String filePath) async {
    final prefs = svc<SharedPreferences>();
    prefs.remove('$_prefsKeyPrefix$filePath');
  }

  @override
  Future<void> save(String filePath, List<int> fileData) async {
    final prefs = svc<SharedPreferences>();
    prefs.setString('$_prefsKeyPrefix$filePath', base64Encode(fileData));
  }
}
