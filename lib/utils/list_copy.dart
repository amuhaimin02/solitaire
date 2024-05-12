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
