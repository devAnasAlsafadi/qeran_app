import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/matchmaker/account/domain/entities/matchmaker_me.dart';
import 'package:qeran/features/matchmaker/account/domain/usecases/get_me_usecase.dart';
import 'package:qeran/features/matchmaker/community/presentation/blocs/guidelines/matchmaker_guidelines_status.dart';

import '../../account/matchmaker_me_fixtures.dart';

class _MockGetMe extends Mock implements GetMeUseCase {}

void main() {
  late _MockGetMe getMe;
  late MatchmakerGuidelinesStatus status;
  setUp(() {
    getMe = _MockGetMe();
    status = MatchmakerGuidelinesStatus(getMe: getMe);
  });

  void meSays(bool? accepted) => when(
    () => getMe(),
  ).thenAnswer((_) async => Right(meWith(accepted: accepted)));

  test('not accepted: owed (G1)', () async {
    meSays(false);

    expect(await status.owed(), isTrue);
  });

  test('accepted: not owed, and not asked again this session', () async {
    meSays(true);

    expect(await status.owed(), isFalse);
    expect(await status.owed(), isFalse);
    verify(() => getMe()).called(1);
  });

  test('a me that doesn\'t say, or that fails: she goes on — the server '
      'is the gate', () async {
    meSays(null);
    expect(await status.owed(), isFalse);

    when(() => getMe()).thenAnswer((_) async => const Left(OfflineFailure()));
    expect(await status.owed(), isFalse);
  });

  test('she agrees: not owed from then on', () async {
    meSays(false);
    expect(await status.owed(), isTrue);

    status.markAccepted();

    expect(await status.owed(), isFalse);
  });

  test('the account changes: asked again, and a read in flight for the '
      'previous one is dropped', () async {
    meSays(true);
    await status.owed();
    status.forget();
    final answer = Completer<Either<Failure, MatchmakerMe>>();
    when(() => getMe()).thenAnswer((_) => answer.future);

    final asking = status.owed();
    status.forget();
    answer.complete(Right(meWith(accepted: true)));
    expect(await asking, isFalse);

    meSays(false);
    expect(await status.owed(), isTrue);
  });
}
