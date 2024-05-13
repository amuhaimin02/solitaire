extension ListCopyExtension<T> on List<T> {
  List<T> copy() {
    return List.from(this);
  }
}

extension NestedListCopyExtension<T> on List<List<T>> {
  List<List<T>> copy() {
    return List<List<T>>.from(map((e) => e.copy()));
  }
}

extension ListExtension<T> on List<T> {
  List<T> extractAll() {
    final copy = List<T>.from(this);
    clear();
    return copy;
  }

  (List<T> a, List<T> b) partition(bool Function(T element) test) {
    final List<T> a = [];
    final List<T> b = [];

    for (final element in this) {
      if (test(element)) {
        a.add(element);
      } else {
        b.add(element);
      }
    }

    return (a, b);
  }

  T toggle(T currentValue) {
    final currentIndex = indexOf(currentValue);
    final newIndex = (currentIndex + 1) % length;
    return this[newIndex];
  }
}
