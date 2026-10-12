import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/features/auth/data/datasources/change_password_remote_datasource.dart';
import 'package:qeran/features/matchmaker/account/data/datasources/matchmaker_account_remote_datasource.dart';

/// Answers every post with [answer].
class _FakeApi extends Fake implements ApiConsumer {
  _FakeApi(this.answer);
  final Object? answer;

  @override
  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
  }) async => answer;
}

const _renewed = {
  'status': 1,
  'data': {'token': 'jwt-2'},
};
const _before = {'status': 1, 'data': null};

/// Both apps change passwords on `Auth/change-password`, which now answers
/// with the new token: each hands it up, or null before Tariq's deploy.
void main() {
  Future<String?> member(Object? answer) =>
      ChangePasswordRemoteDataSourceImpl(
        apiConsumer: _FakeApi(answer),
      ).changePassword(
        currentPassword: 'old-one',
        newPassword: 'new-one-9',
        confirmPassword: 'new-one-9',
      );

  Future<String?> matchmaker(Object? answer) =>
      MatchmakerAccountRemoteDataSourceImpl(
        apiConsumer: _FakeApi(answer),
      ).changePassword(currentPassword: 'old-one', newPassword: 'new-one-9');

  test('the member\'s change hands up the new token', () async {
    expect(await member(_renewed), 'jwt-2');
    expect(await member(_before), isNull);
  });

  test('the matchmaker\'s change hands up the new token', () async {
    expect(await matchmaker(_renewed), 'jwt-2');
    expect(await matchmaker(_before), isNull);
  });
}
