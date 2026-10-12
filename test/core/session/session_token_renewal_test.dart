import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/session/session_expiry.dart';
import 'package:qeran/core/session/session_token_renewal.dart';

/// A password change answers with a new token, as login does, and the server
/// refuses the old one from then on. The new one is adopted, inside the window
/// in which 401s are held; a change with none (before Tariq's deploy, or a
/// failure) keeps the current one.
void main() {
  group('the token in the answer', () {
    test('data.token, as login answers', () {
      expect(
        renewedTokenIn({
          'status': 1,
          'data': {'token': 'jwt-2', 'id': 'u-1'},
        }),
        'jwt-2',
      );
    });

    test('none before the deploy (data: null), an empty one, or no '
        'envelope', () {
      expect(renewedTokenIn({'status': 1, 'data': null}), isNull);
      expect(
        renewedTokenIn({
          'status': 1,
          'data': {'token': ''},
        }),
        isNull,
      );
      expect(renewedTokenIn(null), isNull);
    });
  });

  group('the renewal', () {
    late SessionExpiry expiry;
    late List<String> adopted;
    late SessionTokenRenewal renewal;

    setUp(() {
      expiry = SessionExpiry();
      adopted = [];
      renewal = SessionTokenRenewal(
        expiry: expiry,
        adopt: (token) async => adopted.add(token),
      );
    });

    test('a new token is adopted, and the change succeeds', () async {
      final result = await renewal.run(() async => const Right('jwt-2'));

      expect(adopted, ['jwt-2']);
      expect(result, const Right<Failure, Unit>(unit));
    });

    test('no token: the current one is kept', () async {
      final result = await renewal.run(() async => const Right(null));

      expect(adopted, isEmpty);
      expect(result.isRight(), isTrue);
    });

    test('a failure adopts nothing and passes through', () async {
      const failure = ServerFailure(message: 'errors.generic');

      final result = await renewal.run(() async => const Left(failure));

      expect(adopted, isEmpty);
      expect(result, const Left<Failure, Unit>(failure));
    });

    test('401s are held until the change and its adoption are done', () async {
      final answer = Completer<Either<Failure, String?>>();
      final running = renewal.run(() => answer.future);
      var settled = false;
      unawaited(expiry.settled().then((_) => settled = true));

      await Future<void>.delayed(Duration.zero);
      expect(settled, isFalse);

      answer.complete(const Right('jwt-2'));
      await running;
      await Future<void>.delayed(Duration.zero);
      expect(settled, isTrue);
      expect(adopted, ['jwt-2']);
    });
  });
}
