import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/data/media/file_media_inspector.dart';
import 'package:qeran/features/community/domain/entities/picked_image.dart';
import 'package:qeran/features/community/domain/entities/picked_video.dart';

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

  List<int> box(String brand) => [0, 0, 0, 32, ...'ftyp$brand'.codeUnits, 0];

  test('the container of a video by its ftyp brand, whatever its name: MP4 or '
      'QuickTime', () async {
    final mp4 = write('clip.mov', box('isom'));
    final mov = write('clip.mp4', box('qt  '));
    final avc = write('clip', box('mp42'));

    expect(await inspector.videoContainerOf(mp4), VideoContainer.mp4);
    expect(await inspector.videoContainerOf(mov), VideoContainer.quickTime);
    expect(await inspector.videoContainerOf(avc), VideoContainer.mp4);
  });

  test(
    '3GP, no ftyp box, too short, or missing: not a video we take',
    () async {
      expect(
        await inspector.videoContainerOf(write('a.3gp', box('3gp4'))),
        isNull,
      );
      expect(
        await inspector.videoContainerOf(
          write('a.jpg', [0xFF, 0xD8, 0xFF, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
        ),
        isNull,
      );
      expect(
        await inspector.videoContainerOf(write('short.mp4', [0, 0, 0])),
        isNull,
      );
      expect(await inspector.videoContainerOf('${dir.path}/gone.mp4'), isNull);
    },
  );

  test('the video types config allows', () {
    expect(VideoContainer.mp4.allowedBy(['mp4', 'mov']), isTrue);
    expect(VideoContainer.quickTime.allowedBy(['mp4']), isFalse);
  });
}
