/// FIFO Stack: Operates like a queue (First-In-First-Out)
class FIFOStack<T> {
  final List<T> _list = [];

  /// Pushes an element to the end of the stack.
  void push(T element) {
    _list.add(element); // Add to the end of the list
  }

  /// Pops the first element (FIFO behavior).
  T? pop() {
    if (_list.isEmpty) {
      return null;
    }
    return _list.removeAt(0); // Remove from the front of the list
  }

  /// Peeks at the first element without removing it.
  T? peek() {
    if (_list.isEmpty) {
      return null;
    }
    return _list.first; // Look at the front element
  }

  /// Clears the stack.
  void clear() {
    _list.clear();
  }

  /// Checks if the stack is empty.
  bool get isEmpty => _list.isEmpty;

  /// Returns the number of elements in the stack.
  int get length => _list.length;
}

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

  /// Checks if the stack is empty.
  bool get isEmpty => _list.isEmpty;

  /// Returns the number of elements in the stack.
  int get length => _list.length;
}
