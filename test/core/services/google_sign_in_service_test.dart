import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/services/google_sign_in_service.dart';

class _MockGoogleSignIn extends Mock implements GoogleSignIn {}

class _FakeGoogleSignInAccount extends Fake implements GoogleSignInAccount {}

void main() {
  late _MockGoogleSignIn client;
  late GoogleSignInService service;

  setUp(() {
    client = _MockGoogleSignIn();
    service = GoogleSignInService(client: client);
  });

  test('initializes the plugin exactly once before authentication', () async {
    final account = _FakeGoogleSignInAccount();
    when(() => client.initialize()).thenAnswer((_) async {});
    when(() => client.authenticate()).thenAnswer((_) async => account);

    await Future.wait<void>([service.initialize(), service.initialize()]);
    final result = await service.authenticate();

    expect(result, same(account));
    verify(() => client.initialize()).called(1);
    verify(() => client.authenticate()).called(1);
  });

  test('allows initialization to be retried after a failure', () async {
    var attempts = 0;
    when(() => client.initialize()).thenAnswer((_) async {
      attempts++;
      if (attempts == 1) throw StateError('temporary init failure');
    });

    await expectLater(service.initialize(), throwsStateError);
    await service.initialize();

    expect(attempts, 2);
  });
}
