import 'package:flutter_test/flutter_test.dart';

import 'package:essentials/essentials.dart';

void main() {
  test('Try.success wraps value', () {
    final result = Try.success<int>(42);
    expect(result.isRight(), true);
  });

  test('Try.reject wraps failure', () {
    final result = Try.reject<int>(UnknownFailure('test'));
    expect(result.isLeft(), true);
  });
}
