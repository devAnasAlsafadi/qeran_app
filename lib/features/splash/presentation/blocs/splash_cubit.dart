import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/state/safe_emit.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/services/storage_service.dart';
import 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> with SafeEmit<SplashState> {
  final StorageService secureStorage;
  final StorageService sharedPrefs;

  SplashCubit({required this.secureStorage, required this.sharedPrefs})
    : super(SplashInitial());

  /// Routing rule (product, 2026):
  /// `hasAnsweredQuestions` (mirrored to [StorageKeys.finishedQuestions]) is
  /// the source of truth for the combined onboarding block:
  /// gender + questionnaire + oath. When true, none of those screens may be
  /// re-shown on cold start. Photo upload is optional and never gates Home.
  Future<void> checkAuthStatus() async {
    // No artificial delay: the route decision resolves as fast as storage
    // reads allow. The splash's on-screen duration is driven by the Lottie
    // animation completing (see SplashScreen), not by a timer here.
    //
    // Every path below emits a Navigate* state; a thrown storage read (e.g. a
    // flutter_secure_storage keystore/decryption failure) is caught and falls
    // back to the unauthenticated entry, so the splash's `_pending` gate ALWAYS
    // receives a decision and can never hang waiting for one.
    try {
      // Session FIRST: a user with a valid token is past onboarding by
      // definition and must never be sent back to it. Onboarding is only for
      // the unauthenticated, and only until they've seen it once.
      final String? token = await secureStorage.get<String>(StorageKeys.token);
      if (token == null || token.isEmpty) {
        final bool? seenOnboarding = await sharedPrefs.get<bool>(
          StorageKeys.seenOnboarding,
        );
        emit(
          seenOnboarding == true ? NavigateToLogin() : NavigateToOnboarding(),
        );
        return;
      }

      final String? role = await sharedPrefs.get<String>(StorageKeys.userRole);
      // Backend confirmed via Swagger: `/auth/login` returns `role` as the
      // literal `"Moderator"`. Lowercased here as belt-and-braces against
      // case drift; the legacy `'khataba'` literal was retired with this
      // tightening.
      if (role?.toLowerCase() == 'moderator') {
        emit(NavigateToMatchmakerHome());
        return;
      }

      final bool? isWhatsappVerified = await sharedPrefs.get<bool>(
        StorageKeys.isWhatsappVerified,
      );
      if (isWhatsappVerified != true) {
        emit(NavigateToIncompleteProfile('whatsapp_input'));
        return;
      }

      // Combined onboarding block — gender + questionnaire + oath.
      // `finishedQuestions=true` is set only after /api/Questions/submit
      // succeeds (post-oath), so we don't need to inspect the individual
      // local flags (signed_oath / uploaded_photos) here.
      final bool? finishedQuestions = await sharedPrefs.get<bool>(
        StorageKeys.finishedQuestions,
      );
      if (finishedQuestions != true) {
        // Resume into the block at the latest known progress point. If the
        // user already chose a gender or has a partial questionnaire draft,
        // jump straight to the questionnaire so the cubit can rehydrate;
        // otherwise start at gender selection.
        final draft = await sharedPrefs.get<String>(
          StorageKeys.questionnaireDraft,
        );
        final gender = await sharedPrefs.get<String>(StorageKeys.gender);
        final hasProgress =
            (draft != null && draft.isNotEmpty) ||
            (gender != null && gender.isNotEmpty);
        emit(NavigateToIncompleteProfile(hasProgress ? 'questions' : 'gender'));
        return;
      }

      // Photos are optional — never block Home.
      emit(NavigateToHome());
    } catch (e, s) {
      // Storage read failed — never leave the splash without a decision. Fall
      // back to the unauthenticated entry (same route as a no-token cold
      // start); the user re-authenticates from there.
      AppLogger.error(
        'Splash decision failed — safe fallback to onboarding',
        error: e,
        stack: s,
        tag: 'SPLASH',
      );
      emit(NavigateToOnboarding());
    }
  }
}
