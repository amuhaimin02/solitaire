extension IterableExtension<T> on Iterable<T> {
  int count(bool Function(T) test) {
    return fold(0, (prev, item) => test(item) ? prev + 1 : prev);
  }
}
