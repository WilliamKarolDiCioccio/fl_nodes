import 'dart:math';

import 'package:fl_nodes/src/core/utils/dsa/sparse_set.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SparseSet Tests', () {
    late SparseSet<int> set;

    setUp(() {
      set = SparseSet<int>(pageSize: 64, aggressiveReclaim: true);
    });

    test('InsertAndContains', () {
      expect(set.contains(1), isFalse);

      set.insert(1, 100);

      expect(set.contains(1), isTrue);
      expect(set.get(1), equals(100));

      set.insert(1, 200);

      expect(set.contains(1), isTrue);
      expect(set.get(1), equals(200));
    });

    test('RemoveKey', () {
      set.insert(3, 300);
      set.insert(5, 500);

      expect(set.contains(3), isTrue);
      expect(set.contains(5), isTrue);

      set.remove(3);

      expect(set.contains(3), isFalse);
      expect(set.contains(5), isTrue);
    });

    test('GetMissingReturn', () {
      expect(set.get(10), isNull);
    });

    test('ClearEmptiesSet', () {
      set.insert(7, 700);
      set.insert(8, 800);

      expect(set.size, equals(2));

      set.clear();

      expect(set.size, equals(0));
      expect(set.contains(7), isFalse);
      expect(set.contains(8), isFalse);
    });

    test('ReserveCapacity', () {
      set.reserve(100, 5);

      for (var key = 0; key < 5; ++key) {
        set.insert(key, key * 10);
      }

      for (var key = 0; key < 5; ++key) {
        expect(set.contains(key), isTrue);
        expect(set.get(key), equals(key * 10));
      }

      expect(set.size, equals(5));
    });

    test('DenseIterationOrder', () {
      set.insert(10, 1000);
      set.insert(20, 2000);
      set.insert(15, 1500);
      final keys = set.keys.toList();
      final values = set.values.toList();
      expect(keys.length, equals(3));
      expect(values.length, equals(3));
      expect(keys[0], equals(10));
      expect(values[0], equals(1000));
      expect(keys[1], equals(20));
      expect(values[1], equals(2000));
      expect(keys[2], equals(15));
      expect(values[2], equals(1500));
    });

    test('RealisticInsertRemove', () {
      const keyCount = 1024;
      final keys = List<int>.generate(keyCount, (i) => i);
      final rng = Random(42);

      for (var iter = 0; iter < 100; ++iter) {
        keys.shuffle(rng);

        // insert all
        for (var k in keys) {
          set.insert(k, k);
        }
        expect(set.size, equals(keyCount));

        // remove half
        for (var i = 0; i < keyCount / 2; ++i) {
          set.remove(keys[i]);
        }

        expect(set.size, equals(keyCount ~/ 2));

        // remove rest
        for (var i = keyCount ~/ 2; i < keyCount; ++i) {
          set.remove(keys[i]);
        }

        expect(set.size, equals(0));
      }
    });

    test('PageBoundaryReinsert', () {
      final edgeKeys = [63, 64, 65, 127];

      for (var k in edgeKeys) {
        set.insert(k, k);
      }

      expect(set.size, equals(edgeKeys.length));

      for (var k in edgeKeys) {
        set.remove(k);
      }

      expect(set.size, equals(0));

      for (var k in edgeKeys) {
        set.insert(k, k + 10);
        expect(set.contains(k), isTrue);
        expect(set.get(k), equals(k + 10));
      }

      expect(set.size, equals(edgeKeys.length));
    });
  });
}
