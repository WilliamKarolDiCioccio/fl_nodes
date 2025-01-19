/// LIFO Stack: Operates like a traditional stack (Last-In-First-Out)
class LIFOStack<T> {
  final List<T> _list = [];

  /// Pushes an element to the end of the stack.
  void push(T element) {
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
}
