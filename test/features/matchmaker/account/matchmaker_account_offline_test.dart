import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/features/matchmaker/account/data/datasources/matchmaker_account_remote_datasource.dart';
import 'package:qeran/features/matchmaker/account/data/repositories/matchmaker_account_repository_impl.dart';
import 'package:qeran/generated/locale_keys.g.dart';

class _MockSource extends Mock implements MatchmakerAccountRemoteDataSource {}

/// Offline, every action on her account says «لا يوجد اتصال بالإنترنت», as a
/// member's does — never «حدث خطأ غير متوقع».
void main() {
  late _MockSource source;
  late MatchmakerAccountRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(File('x')));

  setUp(() {
    source = _MockSource();
    repository = MatchmakerAccountRepositoryImpl(source);
    const offline = OfflineException();
    when(() => source.getMe()).thenThrow(offline);
    when(() => source.updateName(any())).thenThrow(offline);
    when(() => source.uploadPhoto(any())).thenThrow(offline);
    when(() => source.deactivate()).thenThrow(offline);
    when(() => source.deleteAccount()).thenThrow(offline);
    when(
      () => source.changePassword(
        currentPassword: any(named: 'currentPassword'),
        newPassword: any(named: 'newPassword'),
      ),
    ).thenThrow(offline);
  });

  final actions = <String, Future<Either<Failure, Object?>> Function()>{
    'load': () => repository.getMe(),
    'save the name': () => repository.updateName('Huda'),
    'upload a photo': () => repository.uploadPhoto(File('p.jpg')),
    'deactivate': () => repository.deactivate(),
    'delete the account': () => repository.deleteAccount(),
    'change the password': () =>
        repository.changePassword(currentPassword: 'a', newPassword: 'b'),
  };

  for (final MapEntry(:key, :value) in actions.entries) {
    test('$key, offline: the offline line', () async {
      final result = await value();

      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isA<OfflineFailure>());
      expect(failure!.message, LocaleKeys.errors_offline);
    });
  }
}
