import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';

import 'push_release_rig.dart';

/// R11 (Tariq): linking a device the server doesn't know answers
/// `DEVICE_NOT_FOUND` — register it, then link again. Bad input answers
/// `VALIDATION_ERROR`, which registering can't fix. The code is live (Tariq,
/// 2026-10-13), so the English sentence the server sent before it no longer
/// counts.
void main() {
  late PushRig rig;

  setUp(() async {
    rig = PushRig();
    await rig.start();
  });

  /// The first link answers [first]; any after it succeeds.
  void firstLinkAnswers(Failure first) {
    var links = 0;
    when(() => rig.link(token: any(named: 'token'))).thenAnswer((i) async {
      rig.calls.add('link ${i.namedArguments[#token]}');
      return links++ == 0 ? Left<Failure, Unit>(first) : const Right(unit);
    });
  }

  Failure coded(String code) =>
      CodedServerFailure(message: 'errors.generic', errorCode: code);

  test('DEVICE_NOT_FOUND: registers, then links again', () async {
    firstLinkAnswers(coded('DEVICE_NOT_FOUND'));

    await rig.service.linkSilently();

    expect(rig.calls, [
      'link $oldToken',
      'register $oldToken',
      'link $oldToken',
    ]);
  });

  test('VALIDATION_ERROR: no register, no second link', () async {
    firstLinkAnswers(coded('VALIDATION_ERROR'));

    await rig.service.linkSilently();

    expect(rig.calls, ['link $oldToken']);
  });

  test('the old English sentence without the code: no register', () async {
    firstLinkAnswers(
      const ServerFailure(message: 'Device not found. Register it first.'),
    );

    await rig.service.linkSilently();

    expect(rig.calls, ['link $oldToken']);
  });

  test('any other refusal: no register, no second link', () async {
    firstLinkAnswers(const ServerFailure(message: 'errors.server'));

    await rig.service.linkSilently();

    expect(rig.calls, ['link $oldToken']);
  });
}
