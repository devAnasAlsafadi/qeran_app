import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/features/badges/data/datasources/badges_remote_datasource.dart';
import 'package:qeran/features/badges/data/repositories/badges_repository_impl.dart';
import 'package:qeran/features/badges/domain/entities/badge_counts.dart';
import 'package:qeran/features/badges/domain/entities/badge_tab_keys.dart';

class _MockRemote extends Mock implements BadgesRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late BadgesRepositoryImpl repository;

  setUp(() {
    remote = _MockRemote();
    repository = BadgesRepositoryImpl(remote);
  });

  test('getBadges passes the counts through as Right', () async {
    when(
      () => remote.getBadges(),
    ).thenAnswer((_) async => const BadgeCounts({BadgeTabKeys.cases: 4}));

    final result = await repository.getBadges();

    expect(result.getOrElse(() => const BadgeCounts.empty()).cases, 4);
  });

  test('getBadges maps a thrown failure to Left', () async {
    when(() => remote.getBadges()).thenThrow(const OfflineException());

    final result = await repository.getBadges();

    expect(result.isLeft(), isTrue);
    result.fold((f) => expect(f, isA<OfflineFailure>()), (_) => fail('Right'));
  });

  test('markTabSeen resolves to Right(unit) on success', () async {
    when(() => remote.markTabSeen(any())).thenAnswer((_) async {});

    final result = await repository.markTabSeen(BadgeTabKeys.likes);

    expect(result, const Right<Failure, Unit>(unit));
  });

  test('markTabSeen maps a thrown failure to Left', () async {
    when(
      () => remote.markTabSeen(any()),
    ).thenThrow(ServerException(message: 'errors.generic'));

    final result = await repository.markTabSeen(BadgeTabKeys.likes);

    expect(result.isLeft(), isTrue);
  });
}
