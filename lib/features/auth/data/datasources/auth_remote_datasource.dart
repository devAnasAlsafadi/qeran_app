import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/api_response.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/domain/entities/success_response.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/core/services/storage_service.dart';
import 'package:qeran/core/services/google_sign_in_service.dart';
import 'package:qeran/core/utils/log_masker.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import '../error_codes.dart';
import '../models/user_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<SuccessResponse<UserModel>> loginWithEmail({
    required String email,
    required String password,
  });

  Future<SuccessResponse<UserModel>> loginWithGoogle();

  Future<SuccessResponse<UserModel>> loginWithApple();

  Future<SuccessResponse<UserModel>> registerUser({
    required String name,
    required String email,
    required String password,
    String? referralCode,
  });

  Future<SuccessResponse<void>> sendWhatsappOtp({required String phoneNumber});

  Future<SuccessResponse<UserModel>> verifyWhatsappOtp({
    required String phoneNumber,
    required String otp,
  });

  Future<SuccessResponse<void>> requestForgotPasswordOtp({
    required String phoneNumber,
  });

  Future<SuccessResponse<void>> verifyForgotPasswordOtp({
    required String phoneNumber,
    required String code,
  });

  Future<SuccessResponse<void>> resetPassword({
    required String phoneNumber,
    required String code,
    required String newPassword,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final ApiConsumer _apiConsumer;
  final SharedPrefService _sharedPref;
  final StorageService _secureStorage;
  final GoogleSignInService _googleSignIn;

  AuthRemoteDataSourceImpl({
    required FirebaseAuth firebaseAuth,
    required ApiConsumer apiConsumer,
    required SharedPrefService sharedPref,
    required StorageService secureStorage,
    required GoogleSignInService googleSignIn,
  }) : _firebaseAuth = firebaseAuth,
       _apiConsumer = apiConsumer,
       _sharedPref = sharedPref,
       _secureStorage = secureStorage,
       _googleSignIn = googleSignIn;

  // ─── Manual Auth (Custom REST API) ────────────────────────────

  @override
  Future<SuccessResponse<UserModel>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final dynamic response;
    try {
      response = await _apiConsumer.post(
        EndPoints.login,
        body: {'email': email, 'password': password},
      );
    } on ServerException catch (e) {
      // Classify HERE, on errorCode — the repository flattens every
      // ServerException into `ServerFailure(message)` and the code is lost
      // after this point. What leaves this method is always a locale KEY.
      throw ServerException(message: _loginFailureKey(e));
    }

    final apiResponse = ApiResponse<UserModel>.fromJson(
      response,
      (json) => UserModel.fromJson(json),
    );

    // Persist the userId and token for the subsequent OTP flow
    if (apiResponse.data != null) {
      await _sharedPref.save(StorageKeys.pendingUserId, apiResponse.data!.id);
      await _persistAuthSession(apiResponse.data!);
    }

    return SuccessResponse.fromApiResponse(apiResponse);
  }

  @override
  Future<SuccessResponse<UserModel>> registerUser({
    required String name,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    // Step 1 only: register-new with displayName, email, password (+ optional
    // affiliate referralCode, omitted from the body when empty/null so an
    // empty field is never sent as "").
    //
    // `displayName` is the informal name shown across the app. The legal
    // name (`realName`) is collected later from profile edit — registration
    // deliberately asks for one name only.
    final response = await _apiConsumer.post(
      EndPoints.register,
      body: {
        'displayName': name,
        'email': email,
        'password': password,
        if (referralCode != null && referralCode.trim().isNotEmpty)
          'referralCode': referralCode.trim(),
      },
    );

    // Parse as dynamic — register-new only returns a partial object (userId),
    // not a full UserModel. Strict parsing would leave data == null and
    // cause the repository to throw a false ServerException.
    final apiResponse = ApiResponse<dynamic>.fromJson(response, (json) => json);

    if (apiResponse.isSuccess && apiResponse.data != null) {
      // Extract and persist the userId for the subsequent add-phone step
      final userId = apiResponse.data['userId'] as String? ?? '';
      await _sharedPref.save(StorageKeys.pendingUserId, userId);
      AppLogger.debug(
        'REGISTER SUCCESS -> Saved userId: $userId',
        tag: 'AUTH_DEBUG',
      );

      // Build a dummy UserModel so the Domain layer always sees data != null
      final dummyUser = UserModel(id: userId, email: email, name: name);

      return SuccessResponse(
        status: apiResponse.status,
        message: apiResponse.message,
        data: dummyUser,
      );
    } else {
      throw ServerException(
        message: apiResponse.message ?? 'Registration failed',
      );
    }
  }

  @override
  Future<SuccessResponse<void>> sendWhatsappOtp({
    required String phoneNumber,
  }) async {
    final userId =
        await _sharedPref.get<String>(StorageKeys.pendingUserId) ?? '';
    AppLogger.debug(
      'ADD-PHONE REQUEST -> userId: "$userId" | phone: ${LogMasker.phone(phoneNumber)}',
      tag: 'AUTH_DEBUG',
    );
    final response = await _apiConsumer.post(
      EndPoints.addPhone,
      body: {'userId': userId, 'phoneNumber': phoneNumber},
    );

    final apiResponse = ApiResponse<void>.fromJson(response, (_) {});
    return SuccessResponse.fromApiResponse(apiResponse);
  }

  @override
  Future<SuccessResponse<UserModel>> verifyWhatsappOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    final userId =
        await _sharedPref.get<String>(StorageKeys.pendingUserId) ?? '';
    AppLogger.debug(
      'VERIFY-OTP REQUEST -> userId: "$userId" | phone: ${LogMasker.phone(phoneNumber)} | ${LogMasker.otp(otp)}',
      tag: 'AUTH_DEBUG',
    );
    final response = await _apiConsumer.post(
      EndPoints.verifyOtp,
      body: {'userId': userId, 'phoneNumber': phoneNumber, 'code': otp},
    );

    final apiResponse = ApiResponse<UserModel>.fromJson(
      response,
      (json) => UserModel.fromJson(json),
    );

    // Persist the auth session: token + userId + role + server flags.
    // No-op when token is empty (defensive — verify-otp success should always
    // include a non-empty token).
    if (apiResponse.data != null) {
      await _persistAuthSession(apiResponse.data!);
    }

    // verify-otp success guarantees the phone is verified, even if the
    // server response omits the flag.
    await _sharedPref.save(StorageKeys.isWhatsappVerified, true);

    // Clean up the temporary userId now that auth flow is complete
    await _sharedPref.remove(StorageKeys.pendingUserId);

    return SuccessResponse.fromApiResponse(apiResponse);
  }

  String _formatForgotPhone(String phone) {
    String formatted = phone.trim().replaceAll('+', '');
    // Remove leading zero after specific country codes if present
    if (formatted.startsWith('9700')) {
      return formatted.replaceFirst('9700', '970');
    } else if (formatted.startsWith('9720')) {
      return formatted.replaceFirst('9720', '972');
    }
    return formatted;
  }

  @override
  Future<SuccessResponse<void>> requestForgotPasswordOtp({
    required String phoneNumber,
  }) async {
    final formattedPhone = _formatForgotPhone(phoneNumber);
    AppLogger.debug(
      'FORGOT PASSWORD REQUEST -> phone: ${LogMasker.phone(formattedPhone)}',
      tag: 'AUTH_DEBUG',
    );
    final response = await _apiConsumer.post(
      EndPoints.forgotPassword,
      body: {'phoneNumber': formattedPhone},
    );

    final apiResponse = ApiResponse<void>.fromJson(response, (_) {});
    return SuccessResponse.fromApiResponse(apiResponse);
  }

  @override
  Future<SuccessResponse<void>> verifyForgotPasswordOtp({
    required String phoneNumber,
    required String code,
  }) async {
    final formattedPhone = _formatForgotPhone(phoneNumber);
    AppLogger.debug(
      'VERIFY FORGOT OTP -> phone: ${LogMasker.phone(formattedPhone)} | ${LogMasker.otp(code)}',
      tag: 'AUTH_DEBUG',
    );
    final response = await _apiConsumer.post(
      EndPoints.verifyForgotPasswordOtp,
      body: {'phoneNumber': formattedPhone, 'code': code},
    );

    final apiResponse = ApiResponse<void>.fromJson(response, (_) {});
    return SuccessResponse.fromApiResponse(apiResponse);
  }

  @override
  Future<SuccessResponse<void>> resetPassword({
    required String phoneNumber,
    required String code,
    required String newPassword,
  }) async {
    final formattedPhone = _formatForgotPhone(phoneNumber);
    AppLogger.debug(
      'RESET PASSWORD -> phone: ${LogMasker.phone(formattedPhone)} | ${LogMasker.otp(code)}',
      tag: 'AUTH_DEBUG',
    );
    final response = await _apiConsumer.post(
      EndPoints.resetPassword,
      body: {
        'phoneNumber': formattedPhone,
        'code': code,
        'newPassword': newPassword,
      },
    );

    final apiResponse = ApiResponse<void>.fromJson(response, (_) {});
    return SuccessResponse.fromApiResponse(apiResponse);
  }

  // ─── Social Auth (Firebase) ───────────────────────────────────

  @override
  Future<SuccessResponse<UserModel>> loginWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.authenticate();
      final idToken = googleUser.authentication.idToken;
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;
      if (user == null) {
        throw AuthException(message: LocaleKeys.errors_auth_failed_google);
      }

      final firebaseIdToken = await user.getIdToken();
      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        throw AuthException(message: LocaleKeys.errors_auth_token_error);
      }

      final displayName = user.displayName ?? googleUser.displayName ?? '';
      AppLogger.info(
        'Google Firebase auth successful: ${user.uid}',
        tag: 'AUTH',
      );

      return _postFirebaseSignIn(
        idToken: firebaseIdToken,
        displayName: displayName,
      );
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Firebase Google login failed', error: e, tag: 'AUTH');
      throw AuthException(message: _mapFirebaseError(e.code));
    } on GoogleSignInException catch (e) {
      AppLogger.error('Google sign-in failed', error: e, tag: 'AUTH');
      throw AuthException(message: 'فشل تسجيل الدخول بـ Google');
    } on AuthException {
      rethrow;
    } catch (e) {
      // Let an offline signal bubble to the repository as OfflineFailure
      // instead of being masked as a generic Google-login failure.
      if (e is OfflineException) rethrow;
      AppLogger.error('Unexpected Google sign-in error', error: e, tag: 'AUTH');
      throw AuthException(message: 'فشل تسجيل الدخول بـ Google');
    }
  }

  @override
  Future<SuccessResponse<UserModel>> loginWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'com.qeran.app.sid',
          redirectUri: Uri.parse(
            'https://qeran-7e6a2.firebaseapp.com/__/auth/handler',
          ),
        ),
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      final userCredential = await _firebaseAuth.signInWithCredential(
        oauthCredential,
      );
      final user = userCredential.user;
      if (user == null) {
        throw AuthException(message: LocaleKeys.errors_auth_failed_apple);
      }

      final firebaseIdToken = await user.getIdToken();
      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        throw AuthException(message: LocaleKeys.errors_auth_token_error);
      }

      final name = [
        appleCredential.givenName,
        appleCredential.familyName,
      ].where((s) => s != null && s.isNotEmpty).join(' ');
      final displayName = name.isNotEmpty ? name : (user.displayName ?? '');
      AppLogger.info(
        'Apple Firebase auth successful: ${user.uid}',
        tag: 'AUTH',
      );

      return _postFirebaseSignIn(
        idToken: firebaseIdToken,
        displayName: displayName,
      );
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Firebase Apple login failed', error: e, tag: 'AUTH');
      throw AuthException(message: _mapFirebaseError(e.code));
    } on SignInWithAppleAuthorizationException catch (e) {
      AppLogger.error('Apple sign-in failed', error: e, tag: 'AUTH');
      throw AuthException(message: LocaleKeys.errors_apple_sign_in_cancelled);
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────

  Future<SuccessResponse<UserModel>> _postFirebaseSignIn({
    required String idToken,
    required String displayName,
  }) async {
    final response = await _apiConsumer.post(
      EndPoints.firebaseSignIn,
      body: {'idToken': idToken, 'displayName': displayName},
    );

    // Parse DEFENSIVELY (mirrors register-new): a brand-new social user can
    // come back as a partial object — no token yet, a numeric id, or missing
    // flags. Strict UserModel parsing plus the repository's data-null guard
    // would turn that into a false failure, so build a guaranteed-non-null user
    // from whatever the server returns and let the routing layer send a new
    // user into onboarding (add phone → questionnaire). A genuine envelope
    // failure (status != 1) still throws.
    final apiResponse = ApiResponse<dynamic>.fromJson(response, (json) => json);
    if (!apiResponse.isSuccess) {
      throw ServerException(
        message: apiResponse.message ?? LocaleKeys.errors_auth_failed_google,
      );
    }
    final data = apiResponse.data;
    final user = data is Map<String, dynamic>
        ? UserModel.fromJson(data)
        : UserModel(id: '', email: '', name: displayName);

    await _sharedPref.save(StorageKeys.pendingUserId, user.id);
    await _persistAuthSession(user);

    return SuccessResponse(
      status: apiResponse.status,
      message: apiResponse.message,
      data: user,
    );
  }

  /// Persists the authenticated session locally so SplashCubit can route
  /// correctly on the next cold start. No-op when the response carries an
  /// empty token (server returns "" until phone is verified). The caller
  /// remains responsible for [StorageKeys.pendingUserId] handling.
  Future<void> _persistAuthSession(UserModel user) async {
    final token = user.token;
    if (token == null || token.isEmpty) return;
    await _secureStorage.save(StorageKeys.token, token);
    if (user.id.isNotEmpty) {
      await _sharedPref.save(StorageKeys.userId, user.id);
    }
    if (user.name.isNotEmpty) {
      await _sharedPref.save(StorageKeys.userName, user.name);
    }
    if (user.email.isNotEmpty) {
      await _sharedPref.save(StorageKeys.userEmail, user.email);
    }
    final role = user.role;
    if (role != null && role.isNotEmpty) {
      await _sharedPref.save(StorageKeys.userRole, role);
    }
    final phoneVerified = user.isPhoneVerified ?? false;
    await _sharedPref.save(StorageKeys.isWhatsappVerified, phoneVerified);
    final answeredQuestions = user.hasAnsweredQuestions ?? false;
    await _sharedPref.save(StorageKeys.finishedQuestions, answeredQuestions);
    AppLogger.debug(
      'AUTH session persisted (verified=$phoneVerified, '
      'answered=$answeredQuestions, role=${role ?? '-'})',
      tag: 'AUTH_DEBUG',
    );
  }

  /// Maps a failed `POST /api/auth/login` onto a locale key.
  ///
  /// Known `errorCode`s translate locally. Anything else falls back to the
  /// transport key the network layer already produced (`errors.timeout`,
  /// `errors.server`, …) and, failing that, `errors.generic` — the server's
  /// own prose is logged for diagnosis but never surfaced.
  String _loginFailureKey(ServerException e) {
    final code = e is CodedServerException ? e.errorCode : null;
    final key = switch (code) {
      AuthErrorCodes.invalidCredentials => LocaleKeys.errors_invalid_credentials,
      AuthErrorCodes.accountDeactivated => LocaleKeys.errors_account_deactivated,
      AuthErrorCodes.validationError => LocaleKeys.errors_bad_request,
      _ => _transportKeyOrGeneric(e.message),
    };
    AppLogger.warning(
      'LOGIN failed — errorCode="${code ?? '-'}" key=$key '
      'serverMessage="${e.message}"',
      tag: 'AUTH',
    );
    return key;
  }

  /// `HttpConsumer` already emits locale keys for transport failures, so keep
  /// those; a raw server sentence becomes `errors.generic`.
  static String _transportKeyOrGeneric(String message) =>
      _kLocaleKeyShape.hasMatch(message.trim())
      ? message.trim()
      : LocaleKeys.errors_generic;

  static final RegExp _kLocaleKeyShape = RegExp(
    r'^[A-Za-z0-9_]+(?:\.[A-Za-z0-9_]+)+$',
  );

  String _mapFirebaseError(String code) {
    return switch (code) {
      'user-not-found' => LocaleKeys.errors_firebase_user_not_found,
      'wrong-password' => LocaleKeys.errors_firebase_wrong_password,
      'invalid-credential' => LocaleKeys.errors_firebase_invalid_credential,
      'email-already-in-use' => LocaleKeys.errors_firebase_email_in_use,
      'weak-password' => LocaleKeys.errors_firebase_weak_password,
      'too-many-requests' => LocaleKeys.errors_too_many_requests,
      'network-request-failed' => LocaleKeys.errors_network_failed,
      _ => LocaleKeys.errors_generic,
    };
  }
}
