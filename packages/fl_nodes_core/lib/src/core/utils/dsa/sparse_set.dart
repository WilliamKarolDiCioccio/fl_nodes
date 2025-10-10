import 'dart:typed_data';

/// A sparse set implementation in Dart, inspired by the C++ version.
/// Uses typed data buffers for improved cache performance.
class SparseSet<T> {
  /// Number of entries per page.
  final int pageSize;

  /// Whether to aggressively reclaim empty pages.
  final bool aggressiveReclaim;

  /// Pages storing sparse indices.
  final List<_Page?> _pages;

  /// Dense list of keys.
  final List<int> _denseKeys;

  /// Dense list of values.
  final List<T> _data;

  /// Constructs a SparseSet with optional page size and reclaim policy.
  SparseSet({this.pageSize = 64, this.aggressiveReclaim = false})
      : _pages = [],
        _denseKeys = [],
        _data = [];

  /// Inserts or updates a key-value pair.
  void insert(int key, T value) {
    final page = _ensurePageExists(key);
    final offset = key % pageSize;

    if (page.present[offset] == 0) {
      page.sparse[offset] = _denseKeys.length;
      _denseKeys.add(key);
      _data.add(value);
      page.present[offset] = 1;
      page.presentCount++;
    } else {
      _data[page.sparse[offset]] = value;
    }
  }

  /// Tries to insert a key-value pair. Returns true if inserted.
  bool tryInsert(int key, T value) {
    final page = _ensurePageExists(key);
    final offset = key % pageSize;

    if (page.present[offset] == 0) {
      page.sparse[offset] = _denseKeys.length;
      _denseKeys.add(key);
      _data.add(value);
      page.present[offset] = 1;
      page.presentCount++;
      return true;
    }
    return false;
  }

  /// Removes a key-value pair.
  void remove(int key) {
    if (_denseKeys.isEmpty) return;
    final pageIndex = key ~/ pageSize;
    if (pageIndex >= _pages.length) return;
    final page = _pages[pageIndex];
    if (page == null) return;
    final offset = key % pageSize;
    if (page.present[offset] == 0) return;

    final denseIdx = page.sparse[offset];
    final lastIdx = _denseKeys.length - 1;

    if (denseIdx < lastIdx) {
      final lastKey = _denseKeys[lastIdx];
      _denseKeys[denseIdx] = lastKey;
      _data[denseIdx] = _data[lastIdx];
      final lastPage = _pages[lastKey ~/ pageSize]!;
      lastPage.sparse[lastKey % pageSize] = denseIdx;
    }

    _denseKeys.removeLast();
    _data.removeLast();
    page.present[offset] = 0;
    page.presentCount--;

    if (aggressiveReclaim && page.presentCount == 0) {
      _pages[pageIndex] = null;
    }
  }

  /// Checks if the key is present.
  bool contains(int key) {
    final pageIndex = key ~/ pageSize;
    if (pageIndex >= _pages.length) return false;
    final page = _pages[pageIndex];
    if (page == null) return false;
    return page.present[key % pageSize] == 1;
  }

  /// Retrieves the value for a key, or null if not found.
  T? get(int key) {
    final pageIndex = key ~/ pageSize;
    if (pageIndex >= _pages.length) return null;
    final page = _pages[pageIndex];
    if (page == null) return null;
    final offset = key % pageSize;
    if (page.present[offset] == 0) return null;
    return _data[page.sparse[offset]];
  }

  /// Number of elements in the set.
  int get size => _denseKeys.length;

  /// Whether the set is empty.
  bool get isEmpty => _denseKeys.isEmpty;

  /// Clears all elements.
  void clear() {
    _denseKeys.clear();
    _data.clear();
    _pages.clear();
  }

  /// Shrinks internal storage to fit elements.
  void shrinkToFit() {
    // Dart List has no trimToSize; manual compaction can be done if necessary.
  }

  /// Reserves space for keys up to [maxKey] and values count [count].
  void reserve(int maxKey, int count) {
    if (aggressiveReclaim) return;
    final requiredPages = (maxKey + pageSize) ~/ pageSize;
    if (_pages.length < requiredPages) {
      _pages.length = requiredPages;
    }
    // Dart List capacity is automatic.
  }

  /// Returns an iterable of keys.
  Iterable<int> get keys => List.unmodifiable(_denseKeys);

  /// Returns an iterable of values.
  Iterable<T> get values => List.unmodifiable(_data);

  /// Computes intersection with another set.
  SparseSet<T> intersection(SparseSet<T> other) {
    final result = SparseSet<T>(
      pageSize: pageSize,
      aggressiveReclaim: aggressiveReclaim,
    );
    if (size < other.size) {
      for (final key in _denseKeys) {
        if (other.contains(key)) {
          result.insert(key, get(key) as T);
        }
      }
    } else {
      for (final key in other._denseKeys) {
        if (contains(key)) {
          result.insert(key, get(key) as T);
        }
      }
    }
    return result;
  }

  /// Merges with another set.
  SparseSet<T> merge(SparseSet<T> other) {
    final result = SparseSet<T>(
      pageSize: pageSize,
      aggressiveReclaim: aggressiveReclaim,
    );
    for (final key in _denseKeys) {
      result.insert(key, get(key) as T);
    }
    for (final key in other._denseKeys) {
      result.insert(key, other.get(key) as T);
    }
    return result;
  }

  /// Ensures the page for [key] exists and returns it.
  _Page _ensurePageExists(int key) {
    final pageIndex = key ~/ pageSize;
    if (pageIndex >= _pages.length) {
      _pages.length = pageIndex + 1;
    }
    return _pages[pageIndex] ??= _Page(pageSize);
  }
}

/// Internal page structure for SparseSet, using typed buffers.
class _Page {
  /// Maps offset to dense index.
  final Uint32List sparse;

  /// Presence bitmap: 0 = absent, 1 = present.
  final Uint8List present;

  /// Count of present entries.
  int presentCount = 0;

  _Page(int pageSize)
      : sparse = Uint32List(pageSize),
        present = Uint8List(pageSize);
}
