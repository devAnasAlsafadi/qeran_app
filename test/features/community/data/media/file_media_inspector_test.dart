import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/data/media/file_media_inspector.dart';
import 'package:qeran/features/community/domain/entities/picked_image.dart';

void main() {
  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('inspect'));
  tearDown(() => dir.delete(recursive: true));

  String write(String name, List<int> bytes) =>
      (File('${dir.path}/$name')..writeAsBytesSync(bytes)).path;

  const inspector = FileMediaInspector();

  test('a JPEG named .heic (Android\'s re-encode) is a JPEG: image.jpg, '
      'image/jpeg, its size', () async {
    final path = write('scaled_IMG.heic', [0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3]);

    final image = await inspector.inspectImage(path);

    expect(image?.format, ImageFormat.jpeg);
    expect(image?.file.fileName, 'image.jpg');
    expect(image?.file.contentType, 'image/jpeg');
    expect(image?.path, path);
    expect(image?.sizeBytes, 7);
  });

  test('a PNG by its signature, whatever its name', () async {
    final path = write('photo.jpg', [
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, //
    ]);

    final image = await inspector.inspectImage(path);

    expect(image?.format, ImageFormat.png);
    expect(image?.file.fileName, 'image.png');
    expect(image?.file.contentType, 'image/png');
  });

  test('a HEIC that wasn\'t converted, unknown bytes, an empty or missing '
      'file: refused', () async {
    final heic = write('a.heic', [0, 0, 0, 24, ...'ftypheic'.codeUnits]);
    final gif = write('a.gif', 'GIF89a..'.codeUnits);
    final empty = write('empty.jpg', []);

    expect(await inspector.inspectImage(heic), isNull);
    expect(await inspector.inspectImage(gif), isNull);
    expect(await inspector.inspectImage(empty), isNull);
    expect(await inspector.inspectImage('${dir.path}/gone.jpg'), isNull);
  });

  test('config\'s types: jpg or jpeg takes a JPEG; png a PNG', () {
    expect(ImageFormat.jpeg.allowedBy(['jpeg']), isTrue);
    expect(ImageFormat.jpeg.allowedBy(['jpg', 'png']), isTrue);
    expect(ImageFormat.jpeg.allowedBy(['png']), isFalse);
    expect(ImageFormat.png.allowedBy(['jpg', 'jpeg']), isFalse);
    expect(ImageFormat.png.allowedBy(['png']), isTrue);
  });
}
