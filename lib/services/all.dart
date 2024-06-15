import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import 'file_handler.dart';
import 'game_serializer.dart';
import 'play_card_generator.dart';
import 'play_table_generator.dart';
import 'system_window.dart';

final services = GetIt.instance;

void setupServices() {
  services.registerLazySingleton<FileHandler>(() {
    if (kIsWeb) {
      return WebFileHandler();
    } else {
      return StandardFileHandler();
    }
  });
  services.registerSingleton(const GameDataSerializer());
  services.registerSingleton(const PlayCardGenerator());
  services.registerSingleton(const PlayTableGenerator());
  services.registerSingleton(const SystemWindow());
}
