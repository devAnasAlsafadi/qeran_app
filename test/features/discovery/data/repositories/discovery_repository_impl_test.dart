import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/features/discovery/data/datasources/discovery_remote_datasource.dart';
import 'package:qeran/features/discovery/data/models/discovery_page_model.dart';
import 'package:qeran/features/discovery/data/repositories/discovery_repository_impl.dart';
import 'package:qeran/features/discovery/domain/entities/like_outcome.dart';

class MockDataSource extends Mock implements DiscoveryRemoteDataSource {}

const _model = DiscoveryPageModel(
  profiles: [],
  pageNumber: 1,
  pageSize: 10,
  totalCount: 0,
  totalPages: 0,
);

void main() {
  late MockDataSource dataSource;
  late DiscoveryRepositoryImpl repository;

  setUp(() {
    dataSource = MockDataSource();
    repository = DiscoveryRepositoryImpl(dataSource);
  });

  group('fetchPage', () {
    test('forwards params to the data source and returns Right(entity)',
        () async {
      when(() => dataSource.fetchPage(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            filterParams: any(named: 'filterParams'),
          )).thenAnswer((_) async => _model);

      final result = await repository.fetchPage(
        page: 2,
        pageSize: 20,
        filterParams: const {'QuestionFilters[18]': 'Single'},
      );

      expect(result.isRight(), isTrue);
      verify(() => dataSource.fetchPage(
            page: 2,
            pageSize: 20,
            filterParams: const {'QuestionFilters[18]': 'Single'},
          )).called(1);
    });

    test('ServerException → Left(ServerFailure)', () async {
      when(() => dataSource.fetchPage(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            filterParams: any(named: 'filterParams'),
          )).thenThrow(ServerException(message: 'boom'));

      final result = await repository.fetchPage();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'boom');
        },
        (_) => fail('expected Left(ServerFailure)'),
      );
    });
  });

  group('likeProfile', () {
    test('LikeAccepted from data source → Right(LikeAccepted)', () async {
      when(() => dataSource.likeProfile(any()))
          .thenAnswer((_) async => const LikeAccepted(likeId: '42'));

      final result = await repository.likeProfile('p-1');

      result.fold(
        (_) => fail('expected Right(LikeAccepted)'),
        (outcome) {
          expect(outcome, isA<LikeAccepted>());
          expect((outcome as LikeAccepted).likeId, '42');
        },
      );
      verify(() => dataSource.likeProfile('p-1')).called(1);
    });

    test('LikePaywall from data source → Right(LikePaywall)', () async {
      when(() => dataSource.likeProfile(any())).thenAnswer(
        (_) async => const LikePaywall(serverMessage: 'quota'),
      );

      final result = await repository.likeProfile('p-1');

      result.fold(
        (_) => fail('expected Right(LikePaywall)'),
        (outcome) => expect(outcome, isA<LikePaywall>()),
      );
    });

    test('ServerException (unmapped) from data source → Left(ServerFailure)',
        () async {
      when(() => dataSource.likeProfile(any()))
          .thenThrow(ServerException(message: 'mystery server error'));

      final result = await repository.likeProfile('p-1');

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'mystery server error');
        },
        (_) => fail('expected Left(ServerFailure)'),
      );
    });
  });

  group('passProfile (skip endpoint)', () {
    test('data source success → Right(unit)', () async {
      when(() => dataSource.skipProfile(any())).thenAnswer((_) async {});

      final result = await repository.passProfile('p-1');

      expect(result, equals(const Right<Failure, Unit>(unit)));
      verify(() => dataSource.skipProfile('p-1')).called(1);
    });

    test('ServerException from data source → Left(ServerFailure)', () async {
      when(() => dataSource.skipProfile(any()))
          .thenThrow(ServerException(message: 'skip-failed'));

      final result = await repository.passProfile('p-1');

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'skip-failed');
        },
        (_) => fail('expected Left(ServerFailure)'),
      );
    });
  });

  group('resetSkippedProfiles', () {
    test('returns Right(count) on success', () async {
      when(
        () => dataSource.resetSkippedProfiles(),
      ).thenAnswer((_) async => 115);

      final result = await repository.resetSkippedProfiles();

      result.fold((_) => fail('expected Right'), (count) => expect(count, 115));
    });

    // Right(0) and Left(Failure) must NOT collapse: one means the reset ran
    // and there was nothing to undo, the other means it did not run. The empty
    // view says something different for each.
    test('Right(0) stays a success, not a failure', () async {
      when(() => dataSource.resetSkippedProfiles()).thenAnswer((_) async => 0);

      final result = await repository.resetSkippedProfiles();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected Right'), (count) => expect(count, 0));
    });

    test('maps a thrown ServerException to Left(ServerFailure)', () async {
      when(
        () => dataSource.resetSkippedProfiles(),
      ).thenThrow(ServerException(message: 'boom'));

      final result = await repository.resetSkippedProfiles();

      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('expected Left(ServerFailure)'),
      );
    });
  });
}
