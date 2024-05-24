sealed class PlayTimeState {
  const PlayTimeState();
}

class PlayTimeRunning extends PlayTimeState {
  final Duration elapsed;

  const PlayTimeRunning(this.elapsed);
}

class PlayTimePaused extends PlayTimeState {
  final Duration elapsed;

  const PlayTimePaused(this.elapsed);
}

class PlayTimeStopped extends PlayTimeState {
  const PlayTimeStopped();
}
