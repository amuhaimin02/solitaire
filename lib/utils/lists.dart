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

extension ExtractListExtension<T> on List<T> {
  List<T> extractAll() {
    final copy = List<T>.from(this);
    clear();
    return copy;
  }
}
