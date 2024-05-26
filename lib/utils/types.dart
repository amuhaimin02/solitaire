extension PrintableDuration on Duration {
  static final maxDisplayableDuration = const Duration(minutes: 100).inSeconds;

  String toMMSSString() {
    final seconds = inSeconds;

    if (seconds >= maxDisplayableDuration) {
      return '99:59';
    }

    final minuteString = seconds ~/ 60;
    final secondString = seconds % 60;

    return '${minuteString.toString().padLeft(2, '0')}:${secondString.toString().padLeft(2, '0')}';
  }
}

extension ChunkableString on String {
  Iterable<String> chunk(int partsLength) sync* {
    assert(
      length % partsLength == 0,
      'string must be divisible by $partsLength',
    );
    for (int i = 0; i < length; i += partsLength) {
      yield substring(i, i + partsLength);
    }
  }
}
