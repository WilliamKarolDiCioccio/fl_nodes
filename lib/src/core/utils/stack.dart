/// Stack: Operates like a traditional stack (Last-In-First-Out)
class Stack<T> {
  final List<T> _list = [];
  final int? _maxSize;

  Stack([this._maxSize]) {
    assert(
      _maxSize == null || _maxSize! > 0,
      "Max size must be null or a positive integer.",
    );
  }

  /// Pushes an element to the end of the stack.
  /// Throws an exception if the stack is at its size limit.
  void push(T element) {
    if (_maxSize != null && _list.length >= _maxSize!) {
      throw StateError(
        "Stack overflow: Cannot add more elements, stack is full.",
      );
    }
    _list.add(element); // Add to the end of the list
  }

  /// Pops the last element (LIFO behavior).
  T? pop() {
    if (_list.isEmpty) {
      return null;
    }
    return _list.removeLast(); // Remove the last element
  }

  /// Peeks at the last element without removing it.
  T? peek() {
    if (_list.isEmpty) {
      return null;
    }
    return _list.last; // Look at the last element
  }

  /// Clears the stack.
  void clear() {
    _list.clear();
  }

  /// Maps each element of the stack to a new value.
  List<R> map<R>(R Function(T) transform) {
    return _list.map(transform).toList();
  }

  /// Returns the stack as a list.
  List<T> toList() {
    return List<T>.from(_list);
  }

  /// Checks if the stack is empty.
  bool get isEmpty => _list.isEmpty;

  /// Returns the number of elements in the stack.
  int get length => _list.length;

  /// Checks if the stack is full (only applicable if a max size is set).
  bool get isFull => _maxSize != null && _list.length >= _maxSize!;
}
