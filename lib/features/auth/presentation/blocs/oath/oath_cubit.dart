import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/features/questionnaire/domain/usecases/submit_answers_usecase.dart';

import '../user_session/user_session_cubit.dart';
import 'oath_state.dart';

/// Owns the submit-after-oath step. The questionnaire screen builds the
/// answers payload and hands it here via the UI; on a successful
/// `/api/Questions/submit` we persist `finishedQuestions=true` and
/// `signedOath=true` so cold-start routing skips the entire onboarding
/// block. Failure leaves the user on the oath screen for retry — the draft
/// is preserved so answers are not lost.
class OathCubit extends Cubit<OathState> with SafeEmit<OathState> {
  final SubmitAnswersUseCase _submitAnswers;
  final SharedPrefService _sharedPrefs;
  final UserSessionCubit _userSession;

  OathCubit({
    required SubmitAnswersUseCase submitAnswers,
    required SharedPrefService sharedPrefs,
    required UserSessionCubit userSession,
  }) : _submitAnswers = submitAnswers,
       _sharedPrefs = sharedPrefs,
       _userSession = userSession,
       super(OathInitial());

  Future<void> submitOath(List<Map<String, dynamic>> answersPayload) async {
    if (state is OathSubmitting) return;
    emit(OathSubmitting());

    final result = await _submitAnswers(answers: answersPayload);
    await result.fold(
      (failure) async {
        AppLogger.error(
          'Submit-after-oath failed: ${failure.message}',
          tag: 'OATH',
        );
        emit(OathFailure(failure.message));
      },
      (_) async {
        AppLogger.info(
          'Submit-after-oath succeeded — marking onboarding block complete',
          tag: 'OATH',
        );
        await _sharedPrefs.save(StorageKeys.signedOath, true);
        await _sharedPrefs.save(StorageKeys.finishedQuestions, true);
        await _sharedPrefs.remove(StorageKeys.questionnaireDraft);
        _userSession.onQuestionsAnswered();
        emit(OathSubmitted());
      },
    );
  }
}
