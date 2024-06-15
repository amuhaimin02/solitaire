class MinMaxTracker<T extends Comparable<T>> {
  T? _min;
  T? _max;

  MinMaxTracker();

  void add(T item) {
    if (_min == null || item.compareTo(min!) < 0) {
      _min = item;
    }
    if (_max == null || item.compareTo(max!) > 0) {
      _max = item;
    }
  }

  T? get min => _min;
  T? get max => _max;
}
