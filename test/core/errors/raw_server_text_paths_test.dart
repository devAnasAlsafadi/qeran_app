import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/features/matchmaker/explore/domain/usecases/get_explore_usecase.dart';
import 'package:qeran/features/matchmaker/explore/presentation/blocs/matchmaker_explore_cubit.dart';
import 'package:qeran/features/support/data/datasources/support_remote_datasource.dart';
import 'package:qeran/features/support/data/repositories/support_repository_impl.dart';
import 'package:qeran/generated/locale_keys.g.dart';

class _MockSupport extends Mock implements SupportRemoteDataSource {}

class _MockExplore extends Mock implements GetExploreUseCase {}

/// The two paths the cleanup audit (`19`, run 11) caught showing the
/// server's sentence: «المساعدة والدعم»'s ticket and her explore list.
void main() {
  test('a refused ticket: the code for the cubit, no sentence', () async {
    final source = _MockSupport();
    when(
      () => source.createTicket(
        categoryId: any(named: 'categoryId'),
        subject: any(named: 'subject'),
        details: any(named: 'details'),
      ),
    ).thenThrow(
      CodedServerException(
        message: 'You have reached the maximum number of open tickets.',
        errorCode: 'SUPPORT_TICKETS_LIMIT_REACHED',
      ),
    );

    final result = await SupportRepositoryImpl(
      source,
    ).createTicket(categoryId: 1, subject: 's', details: 'd');

    final failure = result.fold((f) => f, (_) => fail('expected a failure'));
    expect(failure.message, LocaleKeys.errors_generic);
    expect(
      (failure as CodedServerFailure).errorCode,
      'SUPPORT_TICKETS_LIMIT_REACHED',
    );
  });

  test('her explore list, a query that broke: «حدث خطأ»', () async {
    final explore = _MockExplore();
    when(
      () => explore(
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
        search: any(named: 'search'),
        gender: any(named: 'gender'),
        questionFilters: any(named: 'questionFilters'),
        rangeFrom: any(named: 'rangeFrom'),
        rangeTo: any(named: 'rangeTo'),
      ),
    ).thenAnswer((_) async => throw StateError('Null check operator'));
    final cubit = MatchmakerExploreCubit(getExplore: explore);

    cubit.clearQuery();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.errorMessage, LocaleKeys.errors_generic);
    await cubit.close();
  });

  test(
    'a failure the repository already keyed reaches the list as is',
    () async {
      final explore = _MockExplore();
      when(
        () => explore(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          search: any(named: 'search'),
          gender: any(named: 'gender'),
          questionFilters: any(named: 'questionFilters'),
          rangeFrom: any(named: 'rangeFrom'),
          rangeTo: any(named: 'rangeTo'),
        ),
      ).thenAnswer(
        (_) async =>
            const Left(ServerFailure(message: LocaleKeys.errors_timeout)),
      );
      final cubit = MatchmakerExploreCubit(getExplore: explore);

      cubit.clearQuery();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.errorMessage, LocaleKeys.errors_timeout);
      await cubit.close();
    },
  );
}
