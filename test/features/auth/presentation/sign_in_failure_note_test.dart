import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/auth/domain/entities/user_entity.dart';
import 'package:qeran/features/auth/domain/usecases/login_with_apple_usecase.dart';
import 'package:qeran/features/auth/domain/usecases/login_with_email_usecase.dart';
import 'package:qeran/features/auth/domain/usecases/login_with_google_usecase.dart';
import 'package:qeran/features/auth/presentation/blocs/login/login_bloc.dart';
import 'package:qeran/features/auth/presentation/blocs/login/login_event.dart';
import 'package:qeran/features/auth/presentation/blocs/login/login_state.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/auth/presentation/screens/login_screen/login_screen.dart';
import 'package:qeran/features/auth/presentation/screens/register_screen/register_screen.dart';
import 'package:qeran/features/devices/application/device_bootstrap_service.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../core/shipped_fonts_rig.dart';
import '../../../core/shipped_strings_rig.dart';
import 'signed_in_rig.dart';

class _Google extends Mock implements LoginWithGoogleUseCase {}

class _Apple extends Mock implements LoginWithAppleUseCase {}

class _Email extends Mock implements LoginWithEmailUseCase {}

class _Devices extends Mock implements DeviceBootstrapService {}

class _Session extends Mock implements UserSessionCubit {}

/// Run 7, item 3b: a failed Google or Apple sign-in shows, small under its
/// message, the reference that names the cause; email shows none.
void main() {
  setUpAll(() async {
    await initShippedStrings();
    await loadShippedFonts();
  });

  group('the bloc', () {
    late _Google google;
    late _Apple apple;
    late _Email email;
    late LoginBloc bloc;

    setUp(() {
      google = _Google();
      apple = _Apple();
      email = _Email();
      bloc = LoginBloc(
        loginWithEmail: email,
        loginWithGoogle: google,
        loginWithApple: apple,
        deviceBootstrap: _Devices(),
        userSession: _Session(),
      );
    });
    tearDown(() => bloc.close());

    Future<LoginFailure> failureAfter(LoginEvent event) async {
      final next = bloc.stream.firstWhere((s) => s is LoginFailure);
      bloc.add(event);
      return await next as LoginFailure;
    }

    test('Google: our server refused, so S-<errorCode>', () async {
      when(google.call).thenAnswer(
        (_) async => const Left<Failure, UserEntity>(
          CodedServerFailure(message: 'k', errorCode: 'ACCOUNT_DEACTIVATED'),
        ),
      );
      final failure = await failureAfter(LoginWithGoogleRequested());
      expect(failure.reference, 'S-ACCOUNT_DEACTIVATED');
    });

    test('Apple: the sheet reference it was given', () async {
      when(apple.call).thenAnswer(
        (_) async => const Left<Failure, UserEntity>(
          AuthFailure(message: 'k', reference: 'A-FAILED'),
        ),
      );
      final failure = await failureAfter(LoginWithAppleRequested());
      expect(failure.reference, 'A-FAILED');
    });

    test('email: no reference', () async {
      when(
        () => email.call(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async =>
            const Left<Failure, UserEntity>(ServerFailure(message: 'k')),
      );
      final failure = await failureAfter(
        LoginWithEmailRequested(email: 'a@b.com', password: 'x'),
      );
      expect(failure.reference, isNull);
    });
  });

  for (final (lang, line, note) in [
    ('ar', 'تم إلغاء تسجيل الدخول بـ Google', 'رمز المرجع: G-CANCEL'),
    ('en', 'Google sign-in was cancelled.', 'Reference: G-CANCEL'),
  ]) {
    testWidgets('$lang: the toast says it calmly, the reference small under', (
      tester,
    ) async {
      final login = wireLogin();
      await pumpExit(tester, const LoginScreen(), locale: Locale(lang));
      login.states.add(
        LoginFailure(
          LocaleKeys.errors_google_sign_in_cancelled,
          reference: 'G-CANCEL',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(line), findsOneWidget);
      final small = tester.widget<Text>(find.text(note));
      expect(small.style?.fontSize, QeranTypography.caption.fontSize);
      await settleExit(tester);
    });
  }

  testWidgets('an email failure shows no reference line', (tester) async {
    final login = wireLogin();
    await pumpExit(tester, const LoginScreen());
    login.states.add(LoginFailure(LocaleKeys.errors_generic));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('رمز المرجع'), findsNothing);
    await settleExit(tester);
  });

  testWidgets('register: a Google failure shows its reference too', (
    tester,
  ) async {
    wireRegister();
    final login = wireLogin();
    await pumpExit(tester, const RegisterScreen());
    login.states.add(
      LoginFailure(
        LocaleKeys.errors_auth_failed_google,
        reference: 'G-NET-1009',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('رمز المرجع: G-NET-1009'), findsOneWidget);
    await settleExit(tester);
  });
}
