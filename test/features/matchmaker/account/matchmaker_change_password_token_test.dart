import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/session/session_expiry.dart';
import 'package:qeran/core/session/session_token_renewal.dart';
import 'package:qeran/features/matchmaker/account/domain/usecases/change_password_usecase.dart';
import 'package:qeran/features/matchmaker/account/domain/usecases/deactivate_account_usecase.dart';
import 'package:qeran/features/matchmaker/account/domain/usecases/get_me_usecase.dart';
import 'package:qeran/features/matchmaker/account/domain/usecases/update_name_usecase.dart';
import 'package:qeran/features/matchmaker/account/domain/usecases/upload_account_photo_usecase.dart';
import 'package:qeran/features/matchmaker/account/presentation/blocs/matchmaker_account_cubit.dart';
import 'package:qeran/features/matchmaker/account/presentation/blocs/matchmaker_account_state.dart';

class _GetMe extends Fake implements GetMeUseCase {}

class _UpdateName extends Fake implements UpdateNameUseCase {}

class _UploadPhoto extends Fake implements UploadAccountPhotoUseCase {}

class _Deactivate extends Fake implements DeactivateAccountUseCase {}

/// The server accepts the change and answers with the new token.
class _Renewed extends Fake implements ChangePasswordUseCase {
  @override
  Future<Either<Failure, String?>> call({
    required String currentPassword,
    required String newPassword,
  }) async => const Right('jwt-2');
}

/// The matchmaker app changes passwords on its own path: the new token it
/// brings is adopted too, or her next request would sign her out.
void main() {
  test('her password change adopts the new token, then succeeds', () async {
    final adopted = <String>[];
    final cubit = MatchmakerAccountCubit(
      getMe: _GetMe(),
      updateName: _UpdateName(),
      uploadPhoto: _UploadPhoto(),
      deactivate: _Deactivate(),
      changePassword: _Renewed(),
      renewal: SessionTokenRenewal(
        expiry: SessionExpiry(),
        adopt: (token) async => adopted.add(token),
      ),
    );

    await cubit.changePassword(
      currentPassword: 'old-one',
      newPassword: 'new-one-9',
    );

    expect(adopted, ['jwt-2']);
    expect(cubit.state.outcome, MatchmakerAccountOutcome.changePasswordSuccess);
    await cubit.close();
  });
}
