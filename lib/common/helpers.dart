class Helper {
  /// Map through an [Iterable] with index
  static List<T> enumerate<T>(Iterable items, T decorator(int, T)) {
    int index = 0;
    List<T> list = [];
    for (var item in items) {
      list.add(decorator(index, item));
      index++;
    }
    return list;
  }
}