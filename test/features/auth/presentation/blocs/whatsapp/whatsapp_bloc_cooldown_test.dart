import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/auth/data/error_codes.dart';
import 'package:qeran/features/auth/domain/usecases/send_whatsapp_otp_usecase.dart';
import 'package:qeran/features/auth/domain/usecases/verify_whatsapp_otp_usecase.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/auth/presentation/blocs/whatsapp/whatsapp_bloc.dart';
import 'package:qeran/features/auth/presentation/blocs/whatsapp/whatsapp_event.dart';
import 'package:qeran/features/auth/presentation/blocs/whatsapp/whatsapp_state.dart';
import 'package:qeran/features/devices/application/device_bootstrap_service.dart';
import 'package:qeran/generated/locale_keys.g.dart';

class _MockSend extends Mock implements SendWhatsappOtpUseCase {}

class _MockVerify extends Mock implements VerifyWhatsappOtpUseCase {}

class _MockDevices extends Mock implements DeviceBootstrapService {}

class _MockSession extends Mock implements UserSessionCubit {}

/// B2: the bloc hands the server's wait on to the screens, for a first send
/// and for a resend alike.
void main() {
  late _MockSend send;
  late WhatsappBloc bloc;

  setUp(() {
    send = _MockSend();
    bloc = WhatsappBloc(
      sendOtp: send,
      verifyOtp: _MockVerify(),
      deviceBootstrap: _MockDevices(),
      userSession: _MockSession(),
    );
  });

  tearDown(() => bloc.close());

  Future<WhatsappFailure> failureAfter(WhatsappEvent event) async {
    final failure = bloc.stream.firstWhere((s) => s is WhatsappFailure);
    bloc.add(event);
    return (await failure) as WhatsappFailure;
  }

  void sendFails(Failure failure) => when(
    () => send(phoneNumber: any(named: 'phoneNumber')),
  ).thenAnswer((_) async => Left(failure));

  const cooldown = CodedServerFailure(
    message: LocaleKeys.errors_otp_cooldown,
    errorCode: AuthErrorCodes.otpCooldown,
    data: {'retryAfterSeconds': 42},
  );

  for (final (name, event) in [
    ('a send', SendOtpRequested('+962790000000')),
    ('a resend', ResendOtpRequested('+962790000000')),
  ]) {
    test('$name refused for a cooldown carries its 42 seconds', () async {
      sendFails(cooldown);

      final state = await failureAfter(event);

      expect(state.message, LocaleKeys.errors_otp_cooldown);
      expect(state.retryAfter, const Duration(seconds: 42));
    });
  }

  test('any other failure carries no wait', () async {
    sendFails(const ServerFailure(message: LocaleKeys.errors_generic));

    final state = await failureAfter(ResendOtpRequested('+962790000000'));

    expect(state.retryAfter, isNull);
  });
}
