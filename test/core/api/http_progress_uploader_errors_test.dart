import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/exceptions.dart';

import 'upload_test_rig.dart';

void main() {
  late UploadRig rig;
  setUp(() async {
    rig = UploadRig();
    await rig.setUp();
  });
  tearDown(() => rig.tearDown());

  test('offline: OfflineException before anything is sent', () async {
    when(() => rig.connectivity.isOnline).thenAnswer((_) async => false);
    final upload = rig
        .uploader((request, body) async => jsonAnswer(uploadOk))
        .postFile('p', fieldName: 'image', file: rig.file);

    await expectLater(upload, throwsA(isA<OfflineException>()));
    expect(rig.sent, isNull);
  });

  test('a dropped connection is offline', () async {
    final upload = rig
        .uploader((request, body) async => throw const SocketException('x'))
        .postFile('p', fieldName: 'image', file: rig.file);

    await expectLater(upload, throwsA(isA<OfflineException>()));
  });

  test('the server\'s code comes through', () async {
    final upload = rig
        .uploader((request, body) async {
          await body.toBytes();
          return jsonAnswer({
            'status': 0,
            'errorCode': 'MEDIA_TOO_LARGE',
          }, status: 400);
        })
        .postFile('p', fieldName: 'image', file: rig.file);

    await expectLater(
      upload,
      throwsA(
        isA<CodedServerException>().having(
          (e) => e.errorCode,
          'errorCode',
          'MEDIA_TOO_LARGE',
        ),
      ),
    );
  });

  test('a file that can\'t be read is a plain server error', () async {
    rig.picked.deleteSync();
    final upload = rig
        .uploader((request, body) async => jsonAnswer(uploadOk))
        .postFile('p', fieldName: 'image', file: rig.file);

    await expectLater(upload, throwsA(isA<ServerException>()));
    expect(rig.sent, isNull);
  });
}
