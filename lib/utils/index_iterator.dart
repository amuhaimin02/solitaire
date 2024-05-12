//
// class ClosestIndexIterator extends Iterable<int> implements Iterator<int> {
//   ClosestIndexIterator({required this.count, required this.pivot}) {
//     _time = count;
//     _diff = 0;
//   }
//
//   final int count;
//
//   final int pivot;
//
//   late int _time;
//   late int _diff;
//
//   @override
//   int get current => pivot + _diff;
//
//   @override
//   bool moveNext() {
//     if (_time <= 0) {
//       return false;
//     }
//
//     if (_time != count) {
//       shiftDiff();
//     }
//
//     while ((pivot + _diff < 0) || (pivot + _diff >= count)) {
//       shiftDiff();
//     }
//
//     --_time;
//     return true;
//   }
//
//   void shiftDiff() {
//     if (_diff == 0) {
//       _diff = 1;
//       return;
//     }
//
//     if (_diff > 0) {
//       _diff = -_diff;
//     } else {
//       _diff = _diff.abs() + 1;
//     }
//   }
//
//   @override
//   Iterator<int> get iterator =>
//       ClosestIndexIterator(count: count, pivot: pivot);
// }

class RollingIndexIterator extends Iterable<int> implements Iterator<int> {
  RollingIndexIterator({
    required this.count,
    required this.start,
    this.direction = 1,
  })  : assert(start >= 0 && start < count),
        assert(direction == 1 || direction == -1),
        _current = start,
        _first = true;

  final int count;
  final int start;
  final int direction;

  int _current;
  bool _first;

  @override
  int get current => _current;

  @override
  bool moveNext() {
    if (_first) {
      _first = false;
      return true;
    }

    _current += direction;

    if (_current >= count) {
      _current = 0;
    } else if (_current < 0) {
      _current = count - 1;
    }

    return _current != start;
  }

  @override
  Iterator<int> get iterator =>
      RollingIndexIterator(count: count, start: start, direction: direction);
}
