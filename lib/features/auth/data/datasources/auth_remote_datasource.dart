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
import '../models/user_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<SuccessResponse<UserModel>> loginWithEmail({
    required String email,
    required String password,
  });

  Future<UserModel> loginWithGoogle();

  Future<UserModel> loginWithApple();

  Future<SuccessResponse<UserModel>> registerUser({
    required String name,
    required String email,
    required String password,
  });

  Future<SuccessResponse<void>> sendWhatsappOtp({required String phoneNumber});

  Future<SuccessResponse<UserModel>> verifyWhatsappOtp({
    required String phoneNumber,
    required String otp,
  });

  Future<SuccessResponse<void>> requestForgotPasswordOtp({required String phoneNumber});

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

  AuthRemoteDataSourceImpl({
    required FirebaseAuth firebaseAuth,
    required ApiConsumer apiConsumer,
    required SharedPrefService sharedPref,
    required StorageService secureStorage,
  })  : _firebaseAuth = firebaseAuth,
        _apiConsumer = apiConsumer,
        _sharedPref = sharedPref,
        _secureStorage = secureStorage;

  // ─── Manual Auth (Custom REST API) ────────────────────────────

  @override
  Future<SuccessResponse<UserModel>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _apiConsumer.post(EndPoints.login, body: {
      'email': email,
      'password': password,
    });

    final apiResponse = ApiResponse<UserModel>.fromJson(
      response,
      (json) => UserModel.fromJson(json),
    );

    // Persist the userId and token for the subsequent OTP flow
    if (apiResponse.data != null) {
      await _sharedPref.save(StorageKeys.pendingUserId, apiResponse.data!.id);
      final token = apiResponse.data!.token;
      if (token != null && token.isNotEmpty) {
        await _secureStorage.save(StorageKeys.token, token);
        AppLogger.debug('LOGIN -> Token saved', tag: 'AUTH_DEBUG');
      }
    }

    return SuccessResponse.fromApiResponse(apiResponse);
  }

  @override
  Future<SuccessResponse<UserModel>> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    // Step 1 only: register-new with name, email, password
    final response = await _apiConsumer.post(EndPoints.register, body: {
      'name': name,
      'email': email,
      'password': password,
    });

    // Parse as dynamic — register-new only returns a partial object (userId),
    // not a full UserModel. Strict parsing would leave data == null and
    // cause the repository to throw a false ServerException.
    final apiResponse = ApiResponse<dynamic>.fromJson(response, (json) => json);

    if (apiResponse.isSuccess && apiResponse.data != null) {
      // Extract and persist the userId for the subsequent add-phone step
      final userId = apiResponse.data['userId'] as String? ?? '';
      await _sharedPref.save(StorageKeys.pendingUserId, userId);
      AppLogger.debug('REGISTER SUCCESS -> Saved userId: $userId', tag: 'AUTH_DEBUG');

      // Build a dummy UserModel so the Domain layer always sees data != null
      final dummyUser = UserModel(
        id: userId,
        email: email,
        name: name,
      );

      return SuccessResponse(
        status: apiResponse.status,
        message: apiResponse.message,
        data: dummyUser,
      );
    } else {
      throw ServerException(message: apiResponse.message ?? 'Registration failed');
    }
  }

  @override
  Future<SuccessResponse<void>> sendWhatsappOtp({required String phoneNumber}) async {
    final userId = await _sharedPref.get<String>(StorageKeys.pendingUserId) ?? '';
    AppLogger.debug('ADD-PHONE REQUEST -> userId: "$userId" | phone: "$phoneNumber"', tag: 'AUTH_DEBUG');
    final response = await _apiConsumer.post(EndPoints.addPhone, body: {
      'userId': userId,
      'phoneNumber': phoneNumber,
    });

    final apiResponse = ApiResponse<void>.fromJson(response, (_) {});
    return SuccessResponse.fromApiResponse(apiResponse);
  }

  @override
  Future<SuccessResponse<UserModel>> verifyWhatsappOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    final userId = await _sharedPref.get<String>(StorageKeys.pendingUserId) ?? '';
    AppLogger.debug('VERIFY-OTP REQUEST -> userId: "$userId" | phone: "$phoneNumber" | code: "$otp"', tag: 'AUTH_DEBUG');
    final response = await _apiConsumer.post(EndPoints.verifyOtp, body: {
      'userId': userId,
      'phoneNumber': phoneNumber,
      'code': otp,
    });

    final apiResponse = ApiResponse<UserModel>.fromJson(
      response,
      (json) => UserModel.fromJson(json),
    );
    // Persist the final auth token so all subsequent requests are authenticated
    final token = apiResponse.data?.token;
    if (token != null && token.isNotEmpty) {
      await _secureStorage.save(StorageKeys.token, token);
      AppLogger.debug('VERIFY-OTP -> Token saved', tag: 'AUTH_DEBUG');
    }

    // Mark WhatsApp as verified so SplashCubit routes correctly on restart
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
  Future<SuccessResponse<void>> requestForgotPasswordOtp({required String phoneNumber}) async {
    final formattedPhone = _formatForgotPhone(phoneNumber);
    AppLogger.debug('FORGOT PASSWORD REQUEST -> phone: "$formattedPhone"', tag: 'AUTH_DEBUG');
    final response = await _apiConsumer.post(EndPoints.forgotPassword, body: {
      'phoneNumber': formattedPhone,
    });

    final apiResponse = ApiResponse<void>.fromJson(response, (_) {});
    return SuccessResponse.fromApiResponse(apiResponse);
  }

  @override
  Future<SuccessResponse<void>> verifyForgotPasswordOtp({
    required String phoneNumber,
    required String code,
  }) async {
    final formattedPhone = _formatForgotPhone(phoneNumber);
    AppLogger.debug('VERIFY FORGOT OTP -> phone: "$formattedPhone" | code: "$code"', tag: 'AUTH_DEBUG');
    final response = await _apiConsumer.post(EndPoints.verifyForgotPasswordOtp, body: {
      'phoneNumber': formattedPhone,
      'code': code,
    });

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
    AppLogger.debug('RESET PASSWORD -> phone: "$formattedPhone" | code: "$code"', tag: 'AUTH_DEBUG');
    final response = await _apiConsumer.post(EndPoints.resetPassword, body: {
      'phoneNumber': formattedPhone,
      'code': code,
      'newPassword': newPassword,
    });

    final apiResponse = ApiResponse<void>.fromJson(response, (_) {});
    return SuccessResponse.fromApiResponse(apiResponse);
  }

  // ─── Social Auth (Firebase) ───────────────────────────────────

  @override
  Future<UserModel> loginWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn.instance.authenticate();
      final idToken = googleUser.authentication.idToken;
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) throw AuthException(message: 'فشل تسجيل الدخول بـ Google');
      final token = await user.getIdToken();
      if (token != null && token.isNotEmpty) {
        await _secureStorage.save(StorageKeys.token, token);
      }
      AppLogger.info('Google login successful: ${user.uid}', tag: 'AUTH');

      try {
        final googleAuth = await googleUser.authentication;
        AppLogger.debug(
          'Google Sign-In Response Data:\n'
          '1. Firebase User UID: ${user.uid}\n'
          '2. Email: ${user.email}\n'
          '3. Display Name: ${user.displayName}\n'
          '4. Photo URL: ${user.photoURL}\n'
          '5. Google ID Token: ${googleAuth is Future ? ( googleAuth).idToken : googleAuth.idToken}\n'
          '6. Google Access Token: ${googleAuth is Future ? (googleAuth).idToken : googleAuth.idToken}',
          tag: 'GOOGLE_AUTH_DATA',
        );
      } catch (e) {
        AppLogger.debug('Failed to get auth details for log: $e', tag: 'GOOGLE_AUTH_DATA');
      }

      return UserModel.fromFirebaseUser(
        uid: user.uid,
        name: user.displayName ?? googleUser.displayName ?? '',
        email: user.email ?? googleUser.email,
        photoUrl: user.photoURL,
        token: token,
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
      AppLogger.error('Unexpected Google sign-in error', error: e, tag: 'AUTH');
      throw AuthException(message: 'فشل تسجيل الدخول بـ Google');
    }
  }

  @override
  Future<UserModel> loginWithApple() async {
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

      AppLogger.debug('Apple User Identifier: ${appleCredential.userIdentifier}', tag: 'APPLE_FULL_PAYLOAD');
      AppLogger.debug('Apple Email: ${appleCredential.email}', tag: 'APPLE_FULL_PAYLOAD');
      AppLogger.debug('Apple Given Name: ${appleCredential.givenName}', tag: 'APPLE_FULL_PAYLOAD');
      AppLogger.debug('Apple Family Name: ${appleCredential.familyName}', tag: 'APPLE_FULL_PAYLOAD');
      AppLogger.debug('Apple Identity Token (Raw): ${appleCredential.identityToken}', tag: 'APPLE_FULL_PAYLOAD');
      AppLogger.debug('Apple Authorization Code: ${appleCredential.authorizationCode}', tag: 'APPLE_FULL_PAYLOAD');






      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      final userCredential = await _firebaseAuth.signInWithCredential(oauthCredential);
      final user = userCredential.user;
      if (user == null) throw AuthException(message: 'فشل تسجيل الدخول بـ Apple');
      final name = [appleCredential.givenName, appleCredential.familyName]
          .where((s) => s != null && s.isNotEmpty)
          .join(' ');
      final token = await user.getIdToken();
      if (token != null && token.isNotEmpty) {
        await _secureStorage.save(StorageKeys.token, token);
      }
      AppLogger.info('Apple login successful: ${user.uid}', tag: 'AUTH');
      AppLogger.debug('Firebase UID: ${user.uid}', tag: 'APPLE_FULL_PAYLOAD');
      AppLogger.debug('Firebase Email: ${user.email}', tag: 'APPLE_FULL_PAYLOAD');
      AppLogger.debug('Firebase ID Token: $token', tag: 'APPLE_FULL_PAYLOAD');
      return UserModel.fromFirebaseUser(
        uid: user.uid,
        name: name.isNotEmpty ? name : (user.displayName ?? ''),
        email: user.email ?? '',
        photoUrl: user.photoURL,
        token: token,
      );
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Firebase Apple login failed', error: e, tag: 'AUTH');
      throw AuthException(message: _mapFirebaseError(e.code));
    } on SignInWithAppleAuthorizationException catch (e) {
      AppLogger.error('Apple sign-in failed', error: e, tag: 'AUTH');
      throw AuthException(message: 'تم إلغاء تسجيل الدخول بـ Apple');
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────

  String _mapFirebaseError(String code) {
    return switch (code) {
      'user-not-found' => 'لا يوجد مستخدم بهذا البريد الإلكتروني',
      'wrong-password' => 'كلمة المرور غير صحيحة',
      'invalid-credential' => 'بيانات الدخول غير صحيحة',
      'email-already-in-use' => 'البريد الإلكتروني مستخدم بالفعل',
      'weak-password' => 'كلمة المرور ضعيفة جداً',
      'too-many-requests' => 'طلبات كثيرة، حاول لاحقاً',
      'network-request-failed' => 'تحقق من الاتصال بالإنترنت',
      _ => 'حدث خطأ، حاول مرة أخرى',
    };
  }
}
