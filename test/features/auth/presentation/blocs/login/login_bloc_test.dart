import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/auth/domain/entities/user_entity.dart';
import 'package:qeran/features/auth/domain/usecases/login_with_apple_usecase.dart';
import 'package:qeran/features/auth/domain/usecases/login_with_email_usecase.dart';
import 'package:qeran/features/auth/domain/usecases/login_with_google_usecase.dart';
import 'package:qeran/features/auth/presentation/blocs/login/login_bloc.dart';
import 'package:qeran/features/auth/presentation/blocs/login/login_event.dart';
import 'package:qeran/features/auth/presentation/blocs/login/login_state.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/devices/application/device_bootstrap_service.dart';

class MockLoginWithEmail extends Mock implements LoginWithEmailUseCase {}

class MockLoginWithGoogle extends Mock implements LoginWithGoogleUseCase {}

class MockLoginWithApple extends Mock implements LoginWithAppleUseCase {}

class MockDeviceBootstrap extends Mock implements DeviceBootstrapService {}

class MockUserSession extends Mock implements UserSessionCubit {}

class _FakeUser extends Fake implements UserEntity {}

const tUser = UserEntity(
  id: 'u-1',
  name: 'Test',
  email: 'a@b.c',
  token: 'jwt',
);

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeUser());
  });

  late MockLoginWithEmail loginEmail;
  late MockLoginWithGoogle loginGoogle;
  late MockLoginWithApple loginApple;
  late MockDeviceBootstrap deviceBootstrap;
  late MockUserSession userSession;
  late LoginBloc bloc;

  setUp(() {
    loginEmail = MockLoginWithEmail();
    loginGoogle = MockLoginWithGoogle();
    loginApple = MockLoginWithApple();
    deviceBootstrap = MockDeviceBootstrap();
    userSession = MockUserSession();

    when(() => deviceBootstrap.linkSilently(force: any(named: 'force')))
        .thenAnswer((_) async {});
    when(() => userSession.onAuthenticated(any())).thenAnswer((_) {});

    bloc = LoginBloc(
      loginWithEmail: loginEmail,
      loginWithGoogle: loginGoogle,
      loginWithApple: loginApple,
      deviceBootstrap: deviceBootstrap,
      userSession: userSession,
    );
  });

  tearDown(() => bloc.close());

  test('email success → userSession.onAuthenticated called with user',
      () async {
    when(() => loginEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => const Right<Failure, UserEntity>(tUser));

    final terminal = bloc.stream.firstWhere(
      (s) => s is LoginSuccess || s is LoginFailure,
    );
    bloc.add(LoginWithEmailRequested(
      email: 'a@b.c',
      password: 'pw',
    ));
    final state = await terminal.timeout(const Duration(seconds: 2));

    expect(state, isA<LoginSuccess>());
    verify(() => userSession.onAuthenticated(tUser)).called(1);
  });

  test('email failure → userSession.onAuthenticated NOT called', () async {
    when(() => loginEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer(
      (_) async =>
          const Left<Failure, UserEntity>(ServerFailure(message: 'oops')),
    );

    final terminal = bloc.stream.firstWhere(
      (s) => s is LoginSuccess || s is LoginFailure,
    );
    bloc.add(LoginWithEmailRequested(
      email: 'a@b.c',
      password: 'pw',
    ));
    final state = await terminal.timeout(const Duration(seconds: 2));

    expect(state, isA<LoginFailure>());
    verifyNever(() => userSession.onAuthenticated(any()));
  });
}
