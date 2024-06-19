import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import 'file_handler.dart';
import 'game_serializer.dart';
import 'play_card_generator.dart';
import 'play_table_generator.dart';
import 'system_window.dart';

final srv = GetIt.instance;

void setupServices() {
  srv.registerLazySingleton<FileHandler>(() {
    if (kIsWeb) {
      return WebFileHandler();
    } else {
      return StandardFileHandler();
    }
  });
  srv.registerSingleton(const GameDataSerializer());
  srv.registerSingleton(const PlayCardGenerator());
  srv.registerSingleton(const PlayTableGenerator());
  srv.registerSingleton(const SystemWindow());
  srv.registerSingleton(Logger());
}
