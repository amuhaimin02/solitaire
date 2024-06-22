import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import 'file_handler.dart';
import 'game_serializer.dart';
import 'play_card_generator.dart';
import 'play_table_generator.dart';
import 'sound_effect.dart';
import 'system_window.dart';

final svc = GetIt.instance;

void setupServices() {
  svc.registerLazySingleton<FileHandler>(() {
    if (kIsWeb) {
      return WebFileHandler();
    } else {
      return StandardFileHandler();
    }
  });
  svc.registerSingleton(const GameDataSerializer());
  svc.registerSingleton(const PlayCardGenerator());
  svc.registerSingleton(const PlayTableGenerator());
  svc.registerSingleton(const SystemWindow());
  svc.registerSingleton(SoundEffectManager());
  svc.registerSingleton(Logger());
}
