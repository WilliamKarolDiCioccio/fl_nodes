/// Simple OrderedSet: preserves insertion order and guarantees uniqueness.
class OrderedSet<T> {
  final List<T> _list = [];
  final Set<T> _set = {};

  OrderedSet([Iterable<T>? items]) {
    if (items != null) addAll(items);
  }

  /// Adds [value] if not already present. Returns true if added.
  bool add(T value) {
    if (_set.add(value)) {
      _list.add(value);
      return true;
    }
    return false;
  }

  /// Adds all items (preserving uniqueness).
  void addAll(Iterable<T> items) {
    for (final item in items) {
      add(item);
    }
  }

  bool contains(T value) => _set.contains(value);

  bool get isEmpty => _list.isEmpty;
  bool get isNotEmpty => _list.isNotEmpty;
  int get length => _list.length;

  /// Returns the last element, or null if empty.
  T? get lastOrNull => _list.isNotEmpty ? _list.last : null;

  /// Returns an immutable snapshot list of elements.
  List<T> toList() => List.unmodifiable(_list);

  @override
  String toString() => _list.toString();
}
