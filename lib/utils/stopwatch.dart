class SettableStopwatch extends Stopwatch {
  late int _startMicroseconds;

  SettableStopwatch([this._startMicroseconds = 0]);

  set startDuration(Duration duration) {
    super.reset();
    _startMicroseconds = duration.inMicroseconds;
  }

  @override
  int get elapsedMicroseconds {
    return _startMicroseconds + super.elapsedMicroseconds;
  }

  @override
  int get elapsedMilliseconds {
    return _startMicroseconds ~/ 1000 + super.elapsedMilliseconds;
  }

  @override
  void reset() {
    super.reset();
    _startMicroseconds = 0;
  }
}
