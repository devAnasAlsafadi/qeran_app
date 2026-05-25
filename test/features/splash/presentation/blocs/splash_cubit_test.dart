import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/services/storage_service.dart';
import 'package:qeran/features/splash/presentation/blocs/splash_cubit.dart';
import 'package:qeran/features/splash/presentation/blocs/splash_state.dart';

class MockStorage extends Mock implements StorageService {}

void main() {
  late MockStorage secure;
  late MockStorage prefs;

  setUp(() {
    secure = MockStorage();
    prefs = MockStorage();

    // Defaults — overridden per test as needed.
    when(() => prefs.get<bool>(any())).thenAnswer((_) async => null);
    when(() => prefs.get<String>(any())).thenAnswer((_) async => null);
    when(() => secure.get<String>(any())).thenAnswer((_) async => 'jwt');
    when(() => prefs.get<bool>(StorageKeys.seenOnboarding))
        .thenAnswer((_) async => true);
    when(() => prefs.get<bool>(StorageKeys.isWhatsappVerified))
        .thenAnswer((_) async => true);
  });

  SplashCubit build() =>
      SplashCubit(secureStorage: secure, sharedPrefs: prefs);

  Future<SplashState> waitFor(SplashCubit cubit) async {
    final firstNonInitial =
        cubit.stream.firstWhere((s) => s is! SplashInitial);
    cubit.checkAuthStatus();
    return firstNonInitial.timeout(const Duration(seconds: 5));
  }

  test(
    'finishedQuestions=true → NavigateToHome even if gender/signedOath/'
    'uploadedPhotos are missing locally',
    () async {
      when(() => prefs.get<bool>(StorageKeys.finishedQuestions))
          .thenAnswer((_) async => true);

      final state = await waitFor(build());
      expect(state, isA<NavigateToHome>());
    },
  );

  test(
    'no gender + no draft + finishedQuestions != true → '
    'NavigateToIncompleteProfile("gender")',
    () async {
      when(() => prefs.get<bool>(StorageKeys.finishedQuestions))
          .thenAnswer((_) async => false);
      // gender + draft remain null per default stubs.

      final state = await waitFor(build());
      expect(state, isA<NavigateToIncompleteProfile>());
      expect((state as NavigateToIncompleteProfile).step, 'gender');
    },
  );

  test(
    'gender saved (no draft) → NavigateToIncompleteProfile("questions") '
    'so the questionnaire screen can fetch and resume',
    () async {
      when(() => prefs.get<bool>(StorageKeys.finishedQuestions))
          .thenAnswer((_) async => false);
      when(() => prefs.get<String>(StorageKeys.gender))
          .thenAnswer((_) async => 'Female');

      final state = await waitFor(build());
      expect(state, isA<NavigateToIncompleteProfile>());
      expect((state as NavigateToIncompleteProfile).step, 'questions');
    },
  );

  test(
    'questionnaire draft present → NavigateToIncompleteProfile("questions") '
    'so QuestionnaireCubit.startFlow can restore answers + currentIndex',
    () async {
      when(() => prefs.get<bool>(StorageKeys.finishedQuestions))
          .thenAnswer((_) async => false);
      when(() => prefs.get<String>(StorageKeys.questionnaireDraft))
          .thenAnswer((_) async => '{"currentIndex":2,"answers":{"3":"foo"}}');

      final state = await waitFor(build());
      expect(state, isA<NavigateToIncompleteProfile>());
      expect((state as NavigateToIncompleteProfile).step, 'questions');
    },
  );

  test(
    'isWhatsappVerified != true → NavigateToIncompleteProfile("whatsapp_input")',
    () async {
      when(() => prefs.get<bool>(StorageKeys.isWhatsappVerified))
          .thenAnswer((_) async => false);
      when(() => prefs.get<bool>(StorageKeys.finishedQuestions))
          .thenAnswer((_) async => true);

      final state = await waitFor(build());
      expect(state, isA<NavigateToIncompleteProfile>());
      expect((state as NavigateToIncompleteProfile).step, 'whatsapp_input');
    },
  );
}
