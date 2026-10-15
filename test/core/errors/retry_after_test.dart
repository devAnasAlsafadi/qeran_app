import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/errors/retry_after.dart';

CodedServerFailure withData(Object? data) =>
    CodedServerFailure(message: 'm', errorCode: 'RATE_LIMITED', data: data);

void main() {
  test("the server's seconds, as a number or a numeric string", () {
    expect(retryAfterOf(withData({'retryAfterSeconds': 42})),
        const Duration(seconds: 42));
    expect(retryAfterOf(withData({'retryAfterSeconds': ' 7 '})),
        const Duration(seconds: 7));
  });

  test('a fraction of a second rounds up, never to zero', () {
    expect(retryAfterOf(withData({'retryAfterSeconds': 0.4})),
        const Duration(seconds: 1));
  });

  test('nothing usable → null, so the caller uses its own wait', () {
    expect(retryAfterOf(withData(null)), isNull);
    expect(retryAfterOf(withData({'other': 1})), isNull);
    expect(retryAfterOf(withData({'retryAfterSeconds': 0})), isNull);
    expect(retryAfterOf(withData({'retryAfterSeconds': 'soon'})), isNull);
    expect(retryAfterOf(withData([42])), isNull);
    expect(retryAfterOf(const ServerFailure(message: 'm')), isNull);
  });
}
