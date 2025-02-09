import 'package:flutter/material.dart';

import '../../constants.dart';

/// A `SpatialHashGrid` is a utility class that provides a spatial hashing system.
/// It organizes and queries rectangular objects (`Rect`) within a 2D grid,
/// allowing for efficient spatial lookups.
///
/// The grid divides the 2D space into cells of fixed size (`cellSize`). Each
/// cell maintains references to objects (referred to as "nodes") that overlap
/// with that cell.
class SpatialHashGrid {
  /// The fixed size of each grid cell.
  final double cellSize;

  /// The main grid structure that maps grid cell indices to a set of nodes.
  /// Each node is represented as a tuple containing an identifier (`String`)
  /// and its bounding rectangle (`Rect`).
  final Map<(int, int), Set<(String, Rect)>> grid = {};

  /// Maps each node's identifier (`String`) to the set of grid cells it occupies.
  final Map<String, Set<(int, int)>> nodeToCells = {};

  /// Constructs a `SpatialHashGrid` using a predefined cell size defined in `constants.dart`.
  SpatialHashGrid() : cellSize = kSpatialHashingCellSize;

  /// Calculates the grid cell index (`Tuple2<int, int>`) for a given point in 2D space.
  (int, int) _getGridIndex(Offset point) {
    return (
      (point.dx / cellSize).floor(),
      (point.dy / cellSize).floor(),
    );
  }

  /// Determines all grid cells that a given rectangle (`Rect`) overlaps.
  ///
  /// Returns a set of cell indices (`Tuple2<int, int>`).
  Set<(int, int)> _getCoveredCells(Rect rect) {
    final (int, int) topLeft = _getGridIndex(rect.topLeft);
    final (int, int) bottomRight = _getGridIndex(rect.bottomRight);

    final Set<(int, int)> cells = {};

    for (int x = topLeft.$1; x <= bottomRight.$1; x++) {
      for (int y = topLeft.$2; y <= bottomRight.$2; y++) {
        cells.add((x, y));
      }
    }

    return cells;
  }

  /// Inserts a new node into the spatial hash grid.
  ///
  /// A node is represented by a tuple (`Tuple2<String, Rect>`), where:
  /// - `node.item1` is the unique identifier of the node.
  /// - `node.item2` is the bounding rectangle of the node.
  void insert((String, Rect) node) {
    final Set<(int, int)> cells = _getCoveredCells(node.$2);

    for (final (int, int) cell in cells) {
      if (!grid.containsKey(cell)) {
        grid[cell] = {};
      }

      grid[cell]!.add(node);
    }

    nodeToCells[node.$1] = cells;
  }

  /// Removes a node from the spatial hash grid by its identifier (`nodeId`).
  void remove(String nodeId) {
    if (nodeToCells.containsKey(nodeId)) {
      for (final (int, int) cell in nodeToCells[nodeId]!) {
        if (grid.containsKey(cell)) {
          grid[cell]!.removeWhere((node) => node.$1 == nodeId);
        }
      }

      nodeToCells.remove(nodeId);
    }
  }

  /// Clears all data from the spatial hash grid.
  void clear() {
    grid.clear();
    nodeToCells.clear();
  }

  /// Queries the spatial hash grid for all node identifiers (`String`)
  /// whose rectangles overlap with a given bounding rectangle (`bounds`).
  ///
  /// Returns a set of node identifiers that are within or overlap the bounds.
  Set<String> queryNodeIdsInArea(Rect bounds) {
    final Set<String> nodeIds = {};

    final Set<(int, int)> cells = _getCoveredCells(bounds);

    for (final (int, int) cell in cells) {
      if (grid.containsKey(cell)) {
        for (final (String, Rect) node in grid[cell]!) {
          if (bounds.overlaps(node.$2)) {
            nodeIds.add(node.$1);
          }
        }
      }
    }

    return nodeIds;
  }

  /// Computes the total number of node references stored in the grid.
  ///
  /// Useful for debugging or performance analysis.
  int get numRefs => grid.values.fold(0, (acc, nodes) => acc + nodes.length);
}
