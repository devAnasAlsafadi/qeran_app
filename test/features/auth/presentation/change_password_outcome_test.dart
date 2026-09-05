import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/auth/data/error_codes.dart';
import 'package:qeran/features/auth/domain/repositories/change_password_repository.dart';
import 'package:qeran/features/auth/domain/usecases/change_password_usecase.dart';
import 'package:qeran/features/auth/presentation/blocs/change_password/change_password_cubit.dart';
import 'package:qeran/features/auth/presentation/blocs/change_password/change_password_state.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// A failure carries two facts, and the screen needs both: WHAT to say, and
/// WHERE it belongs. They used to be one — every non-offline failure was
/// pinned under the current-password field — so a validation rejection, an
/// unrecognised code or an outright fault all told the member their current
/// password was wrong. On a password screen that is not vagueness, it is a
/// specific false statement they act on.
///
/// So every case below asserts the EXACT key AND the EXACT slot. Either alone
/// would pass while the other collapsed.
class _ScriptedRepository implements ChangePasswordRepository {
  _ScriptedRepository(this._result);
  final Either<Failure, Unit> _result;

  @override
  Future<Either<Failure, Unit>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async => _result;
}

ChangePasswordCubit cubitFor(Either<Failure, Unit> result) =>
    ChangePasswordCubit(ChangePasswordUseCase(_ScriptedRepository(result)));

/// What the data source hands up after classifying: the message is already a
/// locale key, and the code rides along so the slot can be chosen.
Either<Failure, Unit> classified(String key, String? code) =>
    Left(CodedServerFailure(message: key, errorCode: code));

Future<ChangePasswordState> submit(ChangePasswordCubit cubit) async {
  await cubit.submit(
    currentPassword: 'old-one',
    newPassword: 'new-one-9',
    confirmPassword: 'new-one-9',
  );
  return cubit.state;
}

void main() {
  test('a wrong current password is the one thing anchored to the field', () async {
    final cubit = cubitFor(
      classified(
        LocaleKeys.settings_change_password_incorrect,
        AuthErrorCodes.invalidOldPassword,
      ),
    );

    final state = await submit(cubit);

    expect(state.status, ChangePasswordStatus.failure);
    expect(state.errorKey, LocaleKeys.settings_change_password_incorrect);
    expect(state.errorSlot, ChangePasswordErrorSlot.field);
    await cubit.close();
  });

  test('a server-side mismatch is not a current-password problem', () async {
    // The form already checks that the two new passwords match, so the server
    // disagreeing is unexpected — and it says nothing about the OLD password.
    final cubit = cubitFor(
      classified(
        LocaleKeys.errors_password_mismatch,
        AuthErrorCodes.passwordMismatch,
      ),
    );

    final state = await submit(cubit);

    expect(
      state.errorKey,
      LocaleKeys.errors_password_mismatch,
      reason: 'the exact key — sharing one with the wrong-password case would '
          'make the two outcomes indistinguishable on screen',
    );
    expect(
      state.errorSlot,
      ChangePasswordErrorSlot.banner,
      reason: 'anchoring this under the current-password field accuses an '
          'input that is not at fault',
    );
    await cubit.close();
  });

  test('an unrecognised code does NOT become a password accusation', () async {
    // The bug this whole change exists for.
    final cubit = cubitFor(
      classified(LocaleKeys.errors_generic, 'SOMETHING_TARIQ_ADDS_NEXT'),
    );

    final state = await submit(cubit);

    expect(state.errorKey, LocaleKeys.errors_generic);
    expect(
      state.errorSlot,
      ChangePasswordErrorSlot.banner,
      reason: 'not understanding the answer is not evidence about the '
          "member's password",
    );
    await cubit.close();
  });

  test('offline still reads as offline', () async {
    final cubit = cubitFor(const Left(OfflineFailure()));

    final state = await submit(cubit);

    expect(
      state.errorKey,
      LocaleKeys.errors_offline,
      reason: 'a request that never left the device says nothing about the '
          'password it was carrying',
    );
    expect(state.errorSlot, ChangePasswordErrorSlot.banner);
    await cubit.close();
  });

  test('an unclassified failure is never shown verbatim', () async {
    // A plain ServerFailure never went through the classifier, so its message
    // may be the server's own English prose.
    final cubit = cubitFor(
      const Left(ServerFailure(message: 'The Password field is required.')),
    );

    final state = await submit(cubit);

    expect(state.errorKey, LocaleKeys.errors_generic);
    expect(state.errorSlot, ChangePasswordErrorSlot.banner);
    await cubit.close();
  });

  test('success clears the error and its slot', () async {
    final cubit = cubitFor(const Right(unit));

    final state = await submit(cubit);

    expect(state.status, ChangePasswordStatus.success);
    expect(state.errorKey, isNull);
    expect(state.errorSlot, ChangePasswordErrorSlot.none);
    await cubit.close();
  });
}
