import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/features/community/data/datasources/community_remote_datasource.dart';
import 'package:qeran/features/community/data/repositories/community_repository_impl.dart';
import 'package:qeran/features/community/domain/entities/guidelines_acceptance.dart';

import '../../fixtures/community_mock_harness.dart';

class _MockDataSource extends Mock implements CommunityRemoteDataSource {}

T _right<T>(Either<Failure, T> e) => e.fold((f) => fail('Left: $f'), (r) => r);

/// Accepting the guidelines (§4.1): stored, or asked again because the text
/// changed while it was read — both on the Right; anything else is a
/// failure.
void main() {
  test('the current version is accepted', () async {
    final repo = CommunityRepositoryImpl(seededMock(accepted: false));
    final version = _right(await repo.getGuidelines()).version;

    final answer = _right(await repo.acceptGuidelines(version));

    expect(answer, GuidelinesAcceptance.accepted);
  });

  test('a version no longer current is outdated', () async {
    final repo = CommunityRepositoryImpl(seededMock(accepted: false));
    final version = _right(await repo.getGuidelines()).version;

    final answer = _right(await repo.acceptGuidelines(version - 1));

    expect(answer, GuidelinesAcceptance.outdated);
  });

  test('any other failure stays a failure', () async {
    final ds = _MockDataSource();
    when(() => ds.acceptGuidelines(any())).thenThrow(const OfflineException());
    final repo = CommunityRepositoryImpl(ds);

    final result = await repo.acceptGuidelines(1);

    expect(result, const Left(OfflineFailure()));
  });

  test('a coded refusal other than validation stays a failure', () async {
    final ds = _MockDataSource();
    when(
      () => ds.acceptGuidelines(any()),
    ).thenThrow(CodedServerException(message: 'x', errorCode: 'UNAUTHORIZED'));
    final repo = CommunityRepositoryImpl(ds);

    final result = await repo.acceptGuidelines(1);

    expect(result.isLeft(), isTrue);
  });
}
