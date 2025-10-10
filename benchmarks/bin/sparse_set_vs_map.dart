import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:fl_nodes_core/src/core/containers/sparse_set.dart';

class SparseSetInsert extends BenchmarkBase {
  final int size;

  SparseSetInsert(this.size) : super('SparseSet_Insert_$size');

  @override
  void run() {
    final set = SparseSet<int>();
    for (var i = 0; i < size; i++) {
      set.insert(i, i);
    }
  }
}

class MapInsert extends BenchmarkBase {
  final int size;

  MapInsert(this.size) : super('Map_Insert_$size');

  @override
  void run() {
    final map = <int, int>{};
    for (var i = 0; i < size; i++) {
      map[i] = i;
    }
  }
}

class SparseSetIterate extends BenchmarkBase {
  final int size;
  late SparseSet<int> set;

  SparseSetIterate(this.size) : super('SparseSet_Iterate_$size') {
    set = SparseSet<int>();
    for (var i = 0; i < size; i++) {
      set.insert(i, i);
    }
  }

  @override
  void run() {
    // ignore: unused_local_variable
    var sum = 0;

    for (var value in set.values) {
      sum += value;
    }
  }
}

class MapIterate extends BenchmarkBase {
  final int size;
  late Map<int, int> map;

  MapIterate(this.size) : super('Map_Iterate_$size') {
    map = <int, int>{};
    for (var i = 0; i < size; i++) {
      map[i] = i;
    }
  }

  @override
  void run() {
    var sum = 0;
    map.forEach((_, v) => sum += v);
  }
}

void main() {
  for (var exp = 10; exp <= 20; exp++) {
    final size = 1 << exp;

    SparseSetInsert(size).report();
    MapInsert(size).report();
    SparseSetIterate(size).report();
    MapIterate(size).report();
  }
}
