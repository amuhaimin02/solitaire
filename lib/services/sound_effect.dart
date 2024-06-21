import 'package:audioplayers/audioplayers.dart';

class SoundEffect {
  SoundEffect();

  final balloonPop = SoundEffectItem('audio/balloon_pop.mp3');
  final cardPick = SoundEffectItem('audio/card_pick.wav');

  final cardMove1 =
      SoundEffectItem('audio/card_move_1.wav', multipleSound: true);
  final cardMove2 = SoundEffectItem('audio/card_move_2.mp3');
  final cardFlip1 = SoundEffectItem('audio/card_flip_1.mp3');
  final cardFlip2 = SoundEffectItem('audio/card_flip_2.wav');
  final cardError = SoundEffectItem('audio/card_error.wav');
}

class SoundEffectItem {
  SoundEffectItem(this.assetPath, {this.multipleSound = false}) {
    _setupPlayer();
  }

  void _setupPlayer() async {
    _player = await AudioPool.create(
        source: AssetSource(assetPath), maxPlayers: multipleSound ? 20 : 1);
  }

  final String assetPath;
  final bool multipleSound;
  AudioPool? _player;

  void play() {
    _player?.start();
  }
}
