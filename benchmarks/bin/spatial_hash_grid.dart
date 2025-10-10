import 'dart:math';
import 'dart:ui';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:fl_nodes_core/src/core/containers/spatial_hash_grid.dart';

/// Generates a large list of nodes with random positions and sizes.
List<({String id, Rect rect})> generateNodes(int count, {int seed = 1234}) {
  final random = Random(seed);
  final List<({String id, Rect rect})> nodes = [];
  for (int i = 0; i < count; i++) {
    final double x = random.nextDouble() * 1000;
    final double y = random.nextDouble() * 1000;
    final double width = random.nextDouble() * 50 + 10;
    final double height = random.nextDouble() * 50 + 10;
    nodes.add((id: 'node_$i', rect: Rect.fromLTWH(x, y, width, height)));
  }
  return nodes;
}

/// Benchmark for inserting nodes.
class InsertBenchmark extends BenchmarkBase {
  final int count;
  late List<({String id, Rect rect})> nodes;
  late SpatialHashGrid grid;

  InsertBenchmark(this.count) : super("InsertBenchmark");

  @override
  void setup() {
    grid = SpatialHashGrid();
    nodes = generateNodes(count);
  }

  @override
  void run() {
    for (var node in nodes) {
      grid.insert(node);
    }
  }
}

/// Benchmark for removing nodes.
class RemoveBenchmark extends BenchmarkBase {
  final int count;
  late List<({String id, Rect rect})> nodes;
  late SpatialHashGrid grid;

  RemoveBenchmark(this.count) : super("RemoveBenchmark");

  @override
  void setup() {
    grid = SpatialHashGrid();
    nodes = generateNodes(count);
    for (var node in nodes) {
      grid.insert(node);
    }
  }

  @override
  void run() {
    for (var node in nodes) {
      grid.remove(node.id);
    }
  }
}

/// Benchmark for updating nodes by direct removal and reinsertion.
class DirectUpdateBenchmark extends BenchmarkBase {
  final int count;
  late List<({String id, Rect rect})> nodes;
  late SpatialHashGrid grid;

  DirectUpdateBenchmark(this.count) : super("DirectUpdateBenchmark");

  @override
  void setup() {
    grid = SpatialHashGrid();
    nodes = generateNodes(count);
    for (var node in nodes) {
      grid.insert(node);
    }
  }

  @override
  void run() {
    final random = Random(1234);
    for (int i = 0; i < nodes.length; i++) {
      final bool shouldInflate = random.nextBool();
      final node = nodes[i];
      Rect newRect;
      if (shouldInflate) {
        // Inflate by a factor between 1.0 and 1.5.
        final double factor = 1.0 + random.nextDouble() * 0.5;
        newRect = node.rect.inflate(factor);
      } else {
        newRect = node.rect;
      }
      // Directly remove and reinsert.
      grid.remove(node.id);
      final updatedNode = (id: node.id, rect: newRect);
      grid.insert(updatedNode);
      nodes[i] = updatedNode;
    }
  }
}

/// Benchmark for updating nodes using the grid's update method.
class UpdateMethodBenchmark extends BenchmarkBase {
  final int count;
  late List<({String id, Rect rect})> nodes;
  late SpatialHashGrid grid;

  UpdateMethodBenchmark(this.count) : super("UpdateMethodBenchmark");

  @override
  void setup() {
    grid = SpatialHashGrid();
    nodes = generateNodes(count);
    for (var node in nodes) {
      grid.insert(node);
    }
  }

  @override
  void run() {
    final random = Random(1234);
    for (int i = 0; i < nodes.length; i++) {
      final bool shouldInflate = random.nextBool();
      final node = nodes[i];
      Rect newRect;
      if (shouldInflate) {
        final double factor = 1.0 + random.nextDouble() * 0.5;
        newRect = node.rect.inflate(factor);
      } else {
        newRect = node.rect;
      }
      final updatedNode = (id: node.id, rect: newRect);
      grid.update(updatedNode);
      nodes[i] = updatedNode;
    }
  }
}

void main() {
  const int nodeCount = 10000;

  // Report each benchmark.
  InsertBenchmark(nodeCount).report();
  RemoveBenchmark(nodeCount).report();
  DirectUpdateBenchmark(nodeCount).report();
  UpdateMethodBenchmark(nodeCount).report();
}
