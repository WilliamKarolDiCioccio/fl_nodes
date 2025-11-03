import 'package:flutter_test/flutter_test.dart';

int add(int a, int b) {
  return a + b;
}

void main() {
  test('add function test', () {
    expect(add(2, 3), 5);
    expect(add(-1, 1), 0);
    expect(add(0, 0), 0);
    expect(add(-5, -5), -10);
  });
}
