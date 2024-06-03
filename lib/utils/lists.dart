extension IterableExtension<T> on Iterable<T> {
  int count(bool Function(T) test) {
    return fold(0, (prev, item) => test(item) ? prev + 1 : prev);
  }
}

extension ListExtension<T> on List<T> {
  (List<T> a, List<T> b) partition(bool Function(T element) test) {
    final List<T> a = [];
    final List<T> b = [];

    forEach((element) => test(element) ? a.add(element) : b.add(element));

    return (a, b);
  }
}
