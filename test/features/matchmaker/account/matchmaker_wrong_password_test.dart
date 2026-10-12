import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/core/session/session_expiry.dart';
import 'package:qeran/core/session/session_token_renewal.dart';
import 'package:qeran/features/matchmaker/account/data/datasources/matchmaker_account_remote_datasource.dart';
import 'package:qeran/features/matchmaker/account/data/repositories/matchmaker_account_repository_impl.dart';
import 'package:qeran/features/matchmaker/account/domain/usecases/change_password_usecase.dart';
import 'package:qeran/features/matchmaker/account/domain/usecases/deactivate_account_usecase.dart';
import 'package:qeran/features/matchmaker/account/domain/usecases/get_me_usecase.dart';
import 'package:qeran/features/matchmaker/account/domain/usecases/update_name_usecase.dart';
import 'package:qeran/features/matchmaker/account/domain/usecases/upload_account_photo_usecase.dart';
import 'package:qeran/features/matchmaker/account/presentation/blocs/matchmaker_account_cubit.dart';
import 'package:qeran/features/matchmaker/account/presentation/blocs/matchmaker_account_state.dart';
import 'package:qeran/features/matchmaker/account/presentation/widgets/matchmaker_change_password_sheet.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../core/shipped_strings_rig.dart';

class _MockApi extends Mock implements ApiConsumer {}

class _GetMe extends Fake implements GetMeUseCase {}

class _UpdateName extends Fake implements UpdateNameUseCase {}

class _UploadPhoto extends Fake implements UploadAccountPhotoUseCase {}

class _Deactivate extends Fake implements DeactivateAccountUseCase {}

/// What the server says, in its own words; never shown.
const _serverSentence = 'كلمة المرور القديمة غير صحيحة من الخادم';

/// The shipped `settings.change_password_incorrect` in [lang] — the member's.
String _memberLine(String lang) =>
    ((jsonDecode(File('assets/translations/$lang.json').readAsStringSync())
                as Map<String, dynamic>)['settings']
            as Map<String, dynamic>)['change_password_incorrect']
        as String;

/// Her change-password, from the HTTP answer up: a wrong old password goes by
/// `INVALID_OLD_PASSWORD`, as the member's does, with the member's line.
void main() {
  late _MockApi api;
  late MatchmakerAccountCubit cubit;

  void serverRefuses(String? code) =>
      when(() => api.post(any(), body: any(named: 'body'))).thenThrow(
        code == null
            ? ServerException(message: _serverSentence)
            : CodedServerException(message: _serverSentence, errorCode: code),
      );

  setUp(() {
    api = _MockApi();
    final repository = MatchmakerAccountRepositoryImpl(
      MatchmakerAccountRemoteDataSourceImpl(apiConsumer: api),
    );
    cubit = MatchmakerAccountCubit(
      getMe: _GetMe(),
      updateName: _UpdateName(),
      uploadPhoto: _UploadPhoto(),
      deactivate: _Deactivate(),
      changePassword: ChangePasswordUseCase(repository),
      renewal: SessionTokenRenewal(
        expiry: SessionExpiry(),
        adopt: (_) async {},
      ),
    );
  });

  tearDown(() => cubit.close());

  Future<void> change() =>
      cubit.changePassword(currentPassword: 'wrong-1', newPassword: 'new-12');

  test('a wrong old password: under the field, the member\'s key', () async {
    serverRefuses('INVALID_OLD_PASSWORD');
    await change();

    expect(cubit.state.errorKind, MatchmakerAccountErrorKind.incorrectPassword);
    expect(
      cubit.state.actionErrorKey,
      LocaleKeys.settings_change_password_incorrect,
    );
  });

  test('another code is not about the field, and keeps its own key', () async {
    serverRefuses('USER_NOT_FOUND');
    await change();

    expect(cubit.state.errorKind, MatchmakerAccountErrorKind.generic);
    expect(cubit.state.actionErrorKey, LocaleKeys.errors_account_not_found);
  });

  test('a refusal with no code is the generic error, not her field', () async {
    serverRefuses(null);
    await change();

    expect(cubit.state.errorKind, MatchmakerAccountErrorKind.generic);
    expect(cubit.state.actionErrorKey, LocaleKeys.errors_generic);
  });

  group('the sheet', () {
    setUpAll(initShippedStrings);

    for (final lang in const ['ar', 'en']) {
      testWidgets('shows the member\'s line, never the server\'s [$lang]', (
        tester,
      ) async {
        serverRefuses('INVALID_OLD_PASSWORD');
        final context = await pumpShippedStrings(tester, Locale(lang));
        showMatchmakerChangePasswordSheet(context, cubit: cubit);
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).at(0), 'wrong-1');
        await tester.enterText(find.byType(TextField).at(1), 'new-12');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(find.text(_memberLine(lang)), findsOneWidget);
        expect(find.text(_serverSentence), findsNothing);
      });
    }
  });
}
