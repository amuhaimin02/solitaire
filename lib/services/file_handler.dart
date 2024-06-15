import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final _dataDirectory = AsyncMemoizer<Directory>().runOnce(() {
    return getApplicationDocumentsDirectory();
  });

  @override
  Future<void> save(String filePath, List<int> fileData) async {
    final baseDir = await _dataDirectory;
    final targetFile = File('${baseDir.path}/$filePath');
    targetFile.writeAsBytesSync(fileData);
  }

  @override
  Future<List<int>> load(String filePath) async {
    final baseDir = await _dataDirectory;
    final targetFile = File('${baseDir.path}/$filePath');
    return targetFile.readAsBytesSync();
  }

  @override
  Future<bool> exists(String filePath) async {
    final baseDir = await _dataDirectory;
    final targetFile = File('${baseDir.path}/$filePath');
    return targetFile.existsSync();
  }

  @override
  Future<void> remove(String filePath) async {
    final baseDir = await _dataDirectory;
    final targetFile = File('${baseDir.path}/$filePath');
    if (targetFile.existsSync()) {
      targetFile.deleteSync();
    }
  }

  @override
  Future<List<String>> list(String path) async {
    final baseDir = await _dataDirectory;
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

  final _prefs = AsyncMemoizer<SharedPreferences>().runOnce(() {
    return SharedPreferences.getInstance();
  });

  @override
  Future<bool> exists(String filePath) async {
    final prefs = await _prefs;
    return prefs.containsKey('$_prefsKeyPrefix$filePath');
  }

  @override
  Future<List<String>> list(String path) async {
    final prefs = await _prefs;
    final storedFiles = prefs
        .getKeys()
        .where((key) => key.startsWith(_prefsKeyPrefix))
        .map((key) => key.substring(_prefsKeyPrefix.length)) // Remove prefix
        .toList();
    return storedFiles;
  }

  @override
  Future<List<int>> load(String filePath) async {
    final prefs = await _prefs;
    final storedData = prefs.getString('$_prefsKeyPrefix$filePath');
    if (storedData == null) {
      throw const FileHandlerException('File not found or cannot be loaded');
    }
    return base64Decode(storedData);
  }

  @override
  Future<void> remove(String filePath) async {
    final prefs = await _prefs;
    prefs.remove('$_prefsKeyPrefix$filePath');
  }

  @override
  Future<void> save(String filePath, List<int> fileData) async {
    final prefs = await _prefs;
    prefs.setString('$_prefsKeyPrefix$filePath', base64Encode(fileData));
  }
}
