import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/datasources/secure_storage_service.dart';
import '../../../../core/datasources/shared_pref_service.dart';
import '../../../../core/services/storage_service.dart';
import 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  final StorageService secureStorage;
  final StorageService sharedPrefs;

  SplashCubit({
    required this.secureStorage,
    required this.sharedPrefs,
  }) : super(SplashInitial());

  void checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 3));

    // --- Onboarding ---
    final bool? seenOnboarding = await sharedPrefs.get<bool>(StorageKeys.seenOnboarding);
    if (seenOnboarding != true) {
      emit(NavigateToOnboarding());
      return;
    }


    // ---Token & Firebase Check ---
    final String? token = await secureStorage.get<String>(StorageKeys.token);
    if (token == null || token.isEmpty) {
      emit(NavigateToLogin());
      return;
    }


    final String? role = await sharedPrefs.get<String>(StorageKeys.userRole);
    if (role == 'khataba') {
      emit(NavigateToKhatabaDashboard());
      return;
    }


    // ---  WhatsApp Verification ---
    final bool? isWhatsappVerified = await sharedPrefs.get<bool>(StorageKeys.isWhatsappVerified);
    if (isWhatsappVerified != true) {
      emit(NavigateToIncompleteProfile('whatsapp_input'));
      return;
    }

    // --- Gender Selection ---
    final String? gender = await sharedPrefs.get<String>(StorageKeys.gender);
    if (gender == null || gender.isEmpty) {
      emit(NavigateToIncompleteProfile('gender'));
      return;
    }

    // ---Questions ---
    final bool? finishedQuestions = await sharedPrefs.get<bool>(StorageKeys.finishedQuestions);
    if (finishedQuestions != true) {
      emit(NavigateToIncompleteProfile('gender'));
      return;
    }


    // ---  Oath  ---
    final bool? signedOath = await sharedPrefs.get<bool>(StorageKeys.signedOath);
    if (signedOath != true) {
      emit(NavigateToIncompleteProfile('oath'));
      return;
    }

    emit(NavigateToHome());
  }
}