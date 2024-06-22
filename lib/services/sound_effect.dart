import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';

class SoundEffectManager {
  final Soundpool soundpool;
  final Map<SoundEffect, int> _soundIDs = {};

  SoundEffectManager()
      : soundpool = Soundpool.fromOptions(
            options: const SoundpoolOptions(maxStreams: 8)) {
    initialize();
  }

  Future<void> initialize() async {
    for (final item in SoundEffect.values) {
      final soundID =
          await rootBundle.load('assets/${item.assetPath}').then((soundData) {
        return soundpool.load(soundData);
      });
      _soundIDs[item] = soundID;
    }
  }

  void play(SoundEffect item) {
    final soundID = _soundIDs[item];
    if (soundID != null) {
      soundpool.play(soundID);
    }
  }
}

enum SoundEffect {
  balloonPop('audio/balloon_pop.mp3'),
  cardPick('audio/card_pick.wav'),
  cardMove1('audio/card_move_1.wav'),
  cardMove2('audio/card_move_2.wav'),
  cardFlip1('audio/card_flip_1.wav'),
  cardFlip2('audio/card_flip_2.wav'),
  uiError('audio/ui_error.wav'),
  uiHint('audio/ui_hint.wav'),
  uiDeny('audio/ui_deny.wav');

  final String assetPath;

  const SoundEffect(this.assetPath);
}
