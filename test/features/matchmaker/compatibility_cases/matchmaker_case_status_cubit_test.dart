import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/data/error_codes.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/compatibility_cases_page.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/formal_request_status.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/repositories/compatibility_cases_repository.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/usecases/update_formal_request_status_usecase.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/presentation/blocs/matchmaker_case_status_cubit.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/presentation/blocs/matchmaker_case_status_state.dart';

class _RejectingRepository implements CompatibilityCasesRepository {
  const _RejectingRepository(this.failure);

  final Failure failure;

  @override
  Future<Either<Failure, CompatibilityCasesPage>> getCases({
    required int page,
    required int pageSize,
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, String>> updateFormalRequestStatus({
    required int formalRequestId,
    required FormalRequestStatus newStatus,
  }) async => Left(failure);
}

void main() {
  test(
    'UNAUTHORIZED response is classified for stale permission recovery',
    () async {
      const failure = CodedServerFailure(
        message: 'ليس لديك صلاحية تحديث هذا الطلب',
        errorCode: CompatibilityCasesErrorCodes.unauthorized,
      );
      final cubit = MatchmakerCaseStatusCubit(
        formalRequestId: 70,
        update: const UpdateFormalRequestStatusUseCase(
          _RejectingRepository(failure),
        ),
      );
      addTearDown(cubit.close);

      await cubit.submit(FormalRequestStatus.parentsVisited);

      expect(cubit.state.outcome, CaseStatusOutcome.failure);
      expect(cubit.state.isUnauthorized, isTrue);
      expect(cubit.state.isInvalidTransition, isFalse);
    },
  );

  test(
    'HTTP 403 is classified even when backend omits an error code',
    () async {
      const failure = CodedServerFailure(
        message: 'forbidden',
        errorCode: null,
        statusCode: 403,
      );
      final cubit = MatchmakerCaseStatusCubit(
        formalRequestId: 70,
        update: const UpdateFormalRequestStatusUseCase(
          _RejectingRepository(failure),
        ),
      );
      addTearDown(cubit.close);

      await cubit.submit(FormalRequestStatus.parentsVisited);

      expect(cubit.state.isUnauthorized, isTrue);
    },
  );

  test(
    'the Arabic permission sentence alone is NOT enough — codes only',
    () async {
      // Guards the removal of the message-matching shim. The backend now
      // returns 403 + UNAUTHORIZED, so the exact Arabic string carries no
      // classification weight; matching on it would resurrect a rule that
      // silently breaks the moment anyone rewords the copy.
      const failure = CodedServerFailure(
        message: 'ليس لديك صلاحية تحديث هذا الطلب',
        errorCode: null,
      );
      final cubit = MatchmakerCaseStatusCubit(
        formalRequestId: 6,
        update: const UpdateFormalRequestStatusUseCase(
          _RejectingRepository(failure),
        ),
      );
      addTearDown(cubit.close);

      await cubit.submit(FormalRequestStatus.parentsVisited);

      expect(cubit.state.outcome, CaseStatusOutcome.failure);
      expect(cubit.state.isUnauthorized, isFalse);
    },
  );

  test('AuthFailure (401 session loss) still classifies', () async {
    const failure = AuthFailure(message: 'errors.unauthorized');
    final cubit = MatchmakerCaseStatusCubit(
      formalRequestId: 8,
      update: const UpdateFormalRequestStatusUseCase(
        _RejectingRepository(failure),
      ),
    );
    addTearDown(cubit.close);

    await cubit.submit(FormalRequestStatus.parentsVisited);

    expect(cubit.state.isUnauthorized, isTrue);
  });
}
