import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'file_handler.dart';
import 'game_serializer.dart';
import 'play_card_generator.dart';
import 'play_table_generator.dart';
import 'save_directory.dart';
import 'sound_effects.dart';
import 'system_window.dart';

final svc = GetIt.instance;

Future<void> setupServices() async {
  svc.registerLazySingleton<FileHandler>(() {
    if (kIsWeb) {
      return WebFileHandler();
    } else {
      return StandardFileHandler();
    }
  });
  svc.registerSingleton(await SharedPreferences.getInstance());
  svc.registerSingleton(await SaveDirectory.getInstance());
  svc.registerSingleton(const GameDataSerializer());
  svc.registerSingleton(const PlayCardGenerator());
  svc.registerSingleton(const PlayTableGenerator());
  svc.registerSingleton(const SystemWindow());
  svc.registerSingleton(SoundEffectsManager());
  svc.registerSingleton(Logger());
}
