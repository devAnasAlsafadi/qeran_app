import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../data/matchmaker_user_error_codes.dart';
import '../../domain/usecases/approve_user_usecase.dart';
import '../../domain/usecases/reject_user_usecase.dart';
import '../../domain/usecases/request_image_user_usecase.dart';
import 'matchmaker_user_actions_state.dart';

/// Drives the approve / reject / request-image actions for one user
/// ([userId]). Created per profile screen (factory). A single in-flight
/// slot guards against double-submit, and each completed action publishes a
/// one-shot [MatchmakerActionOutcome] the screen turns into a snackbar +
/// (for approve/reject) a pop.
class MatchmakerUserActionsCubit extends Cubit<MatchmakerUserActionsState>
    with SafeEmit<MatchmakerUserActionsState> {
  final ApproveUserUseCase _approve;
  final RejectUserUseCase _reject;
  final RequestImageUserUseCase _requestImage;
  final String userId;

  MatchmakerUserActionsCubit({
    required this.userId,
    required ApproveUserUseCase approve,
    required RejectUserUseCase reject,
    required RequestImageUserUseCase requestImage,
  }) : _approve = approve,
       _reject = reject,
       _requestImage = requestImage,
       super(const MatchmakerUserActionsState());

  Future<void> approve() => _run(
    MatchmakerUserAction.approve,
    () => _approve(userId),
    MatchmakerActionOutcome.approveSuccess,
  );

  Future<void> reject(String reason) => _run(
    MatchmakerUserAction.reject,
    () => _reject(userId: userId, reason: reason),
    MatchmakerActionOutcome.rejectSuccess,
  );

  Future<void> requestImage() => _run(
    MatchmakerUserAction.requestImage,
    () => _requestImage(userId),
    MatchmakerActionOutcome.requestImageSuccess,
  );

  Future<void> _run(
    MatchmakerUserAction action,
    Future<Either<Failure, String>> Function() call,
    MatchmakerActionOutcome onSuccess,
  ) async {
    if (state.isBusy) return; // guard double-submit
    emit(
      state.copyWith(
        inFlight: action,
        clearError: true,
        errorKind: MatchmakerActionErrorKind.none,
      ),
    );
    final result = await call();
    if (isClosed) return;
    result.fold(
      (failure) {
        AppLogger.warning(
          'MATCHMAKER — ${action.name} failed raw="${failure.message}"',
          tag: 'MATCHMAKER',
        );
        emit(
          state.copyWith(
            clearInFlight: true,
            outcome: MatchmakerActionOutcome.failure,
            eventVersion: state.eventVersion + 1,
            errorMessage: failure.message,
            errorKind: _classify(failure),
          ),
        );
      },
      (_) => emit(
        state.copyWith(
          clearInFlight: true,
          outcome: onSuccess,
          eventVersion: state.eventVersion + 1,
          clearError: true,
          errorKind: MatchmakerActionErrorKind.none,
        ),
      ),
    );
  }

  MatchmakerActionErrorKind _classify(Failure failure) {
    if (failure is CodedServerFailure &&
        failure.errorCode == MatchmakerUserErrorCodes.unauthorized) {
      return MatchmakerActionErrorKind.unauthorized;
    }
    return MatchmakerActionErrorKind.generic;
  }
}
