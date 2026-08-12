import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../data/matchmaker_user_error_codes.dart';
import '../../domain/usecases/update_text_answer_usecase.dart';
import 'matchmaker_answer_save_state.dart';

/// Drives the text-answer save for one user ([userId]). A single in-flight
/// slot (keyed by questionId) guards double-submit; each completed save
/// publishes a one-shot outcome the screen turns into a snackbar + an
/// in-place list update.
class MatchmakerAnswerSaveCubit extends Cubit<MatchmakerAnswerSaveState>
    with SafeEmit<MatchmakerAnswerSaveState> {
  final UpdateTextAnswerUseCase _updateTextAnswer;
  final String userId;

  MatchmakerAnswerSaveCubit({
    required this.userId,
    required UpdateTextAnswerUseCase updateTextAnswer,
  }) : _updateTextAnswer = updateTextAnswer,
       super(const MatchmakerAnswerSaveState());

  Future<void> save({
    required int questionId,
    required String textAnswer,
  }) async {
    if (state.inFlightQuestionId != null) return; // guard double-submit
    emit(
      state.copyWith(
        inFlightQuestionId: questionId,
        clearError: true,
        errorKind: AnswerSaveErrorKind.none,
      ),
    );
    final result = await _updateTextAnswer(
      userId: userId,
      questionId: questionId,
      textAnswer: textAnswer,
    );
    if (isClosed) return;
    result.fold(
      (failure) {
        AppLogger.warning(
          'MATCHMAKER — save answer q=$questionId failed '
          'raw="${failure.message}"',
          tag: 'MATCHMAKER',
        );
        emit(
          state.copyWith(
            clearInFlight: true,
            outcome: AnswerSaveOutcome.failure,
            eventVersion: state.eventVersion + 1,
            lastQuestionId: questionId,
            errorMessage: failure.message,
            errorKind: _classify(failure),
          ),
        );
      },
      (_) => emit(
        state.copyWith(
          clearInFlight: true,
          outcome: AnswerSaveOutcome.success,
          eventVersion: state.eventVersion + 1,
          lastQuestionId: questionId,
          lastAnswer: textAnswer,
          clearError: true,
          errorKind: AnswerSaveErrorKind.none,
        ),
      ),
    );
  }

  AnswerSaveErrorKind _classify(Failure failure) {
    if (failure is CodedServerFailure &&
        failure.errorCode == MatchmakerUserErrorCodes.unauthorized) {
      return AnswerSaveErrorKind.unauthorized;
    }
    return AnswerSaveErrorKind.generic;
  }
}
