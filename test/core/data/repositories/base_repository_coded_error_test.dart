import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/errors/exceptions.dart';

class _RepositoryHarness with BaseRepository {
  Future<Either<Failure, T>> run<T>(Future<T> Function() call) =>
      executeApiCall(call);
}

void main() {
  test(
    'preserves errorCode and statusCode from CodedServerException',
    () async {
      final result = await _RepositoryHarness().run<String>(
        () async => throw CodedServerException(
          message: 'not assigned',
          errorCode: 'UNAUTHORIZED',
          statusCode: 200,
        ),
      );

      result.fold((failure) {
        expect(failure, isA<CodedServerFailure>());
        final coded = failure as CodedServerFailure;
        expect(coded.message, 'not assigned');
        expect(coded.errorCode, 'UNAUTHORIZED');
        expect(coded.statusCode, 200);
      }, (_) => fail('Expected a failure'));
    },
  );
}
