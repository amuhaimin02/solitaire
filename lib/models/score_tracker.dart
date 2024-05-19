class ScoreTracker {
  int _value = 0;

  int get value => _value;

  void add(int value) {
    _value += value;
  }

  void subtract(int value) {
    _value -= value;
  }
}
