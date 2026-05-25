import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/domain/entities/success_response.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/auth/presentation/blocs/oath/oath_cubit.dart';
import 'package:qeran/features/auth/presentation/blocs/oath/oath_state.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/questionnaire/domain/usecases/submit_answers_usecase.dart';

class MockSubmitAnswers extends Mock implements SubmitAnswersUseCase {}

class MockSharedPrefs extends Mock implements SharedPrefService {}

class MockUserSession extends Mock implements UserSessionCubit {}

void main() {
  late MockSubmitAnswers submitAnswers;
  late MockSharedPrefs prefs;
  late MockUserSession userSession;
  late OathCubit cubit;

  final payload = [
    {
      'questionId': '1',
      'textAnswer': '',
      'selectedOptions': ['5'],
    }
  ];

  setUp(() {
    submitAnswers = MockSubmitAnswers();
    prefs = MockSharedPrefs();
    userSession = MockUserSession();

    when(() => prefs.save<bool>(any(), any())).thenAnswer((_) async {});
    when(() => prefs.remove(any())).thenAnswer((_) async {});
    when(() => userSession.onQuestionsAnswered()).thenAnswer((_) {});

    cubit = OathCubit(
      submitAnswers: submitAnswers,
      sharedPrefs: prefs,
      userSession: userSession,
    );
  });

  test(
    'success → persists finishedQuestions=true + signedOath=true, clears draft, '
    'emits OathSubmitted',
    () async {
      when(() => submitAnswers(answers: any(named: 'answers'))).thenAnswer(
        (_) async =>
            Right<Failure, SuccessResponse>(SuccessResponse(status: 1)),
      );

      final next = cubit.stream.firstWhere((s) => s is! OathInitial && s is! OathSubmitting);
      await cubit.submitOath(payload);
      final terminal = await next.timeout(const Duration(seconds: 2));

      expect(terminal, isA<OathSubmitted>());
      verify(() => prefs.save<bool>(StorageKeys.signedOath, true)).called(1);
      verify(() => prefs.save<bool>(StorageKeys.finishedQuestions, true))
          .called(1);
      verify(() => prefs.remove(StorageKeys.questionnaireDraft)).called(1);
    },
  );

  test(
    'failure → emits OathFailure and does NOT persist finishedQuestions',
    () async {
      when(() => submitAnswers(answers: any(named: 'answers'))).thenAnswer(
        (_) async => const Left<Failure, SuccessResponse>(
          ServerFailure(message: 'boom'),
        ),
      );

      final next = cubit.stream.firstWhere((s) => s is! OathInitial && s is! OathSubmitting);
      await cubit.submitOath(payload);
      final terminal = await next.timeout(const Duration(seconds: 2));

      expect(terminal, isA<OathFailure>());
      expect((terminal as OathFailure).message, 'boom');
      verifyNever(() => prefs.save<bool>(StorageKeys.finishedQuestions, true));
      verifyNever(() => prefs.save<bool>(StorageKeys.signedOath, true));
      verifyNever(() => prefs.remove(StorageKeys.questionnaireDraft));
    },
  );
}
