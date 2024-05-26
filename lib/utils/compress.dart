import 'dart:typed_data';

import 'package:gzip/gzip.dart';

final _compressor = GZip();

Future<List<int>> compressText(String rawData) async {
  return await _compressor.compress(Uint8List.fromList(rawData.codeUnits));
}

Future<String> decompressText(List<int> rawData) async {
  return String.fromCharCodes(
      await _compressor.decompress(Uint8List.fromList(rawData)));
}
