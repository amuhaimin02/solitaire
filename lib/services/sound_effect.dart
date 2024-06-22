import 'package:audioplayers/audioplayers.dart';

class SoundEffect {
  SoundEffect() {
    AudioPlayer.global.setAudioContext(AudioContext(
      android: const AudioContextAndroid(
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.game,
      ),
      iOS: AudioContextIOS(),
    ));
  }

  final balloonPop = SoundEffectItem('audio/balloon_pop.mp3');
  final cardPick = SoundEffectItem('audio/card_pick.wav');

  final cardMove1 =
      SoundEffectItem('audio/card_move_1.wav', multipleSound: true);
  final cardMove2 = SoundEffectItem('audio/card_move_2.wav');
  final cardFlip1 = SoundEffectItem('audio/card_flip_1.wav');
  final cardFlip2 = SoundEffectItem('audio/card_flip_2.wav');
  final uiError = SoundEffectItem('audio/ui_error.wav');
  final uiHint = SoundEffectItem('audio/ui_hint.wav');
  final uiDeny = SoundEffectItem('audio/ui_deny.wav');
}

class SoundEffectItem {
  SoundEffectItem(this.assetPath, {this.multipleSound = false}) {
    _setupPlayer();
  }

  void _setupPlayer() async {
    _player = await AudioPool.create(
        source: AssetSource(assetPath), maxPlayers: multipleSound ? 8 : 1);
  }

  final String assetPath;
  final bool multipleSound;
  AudioPool? _player;

  void play() {
    _player?.start();
  }
}
