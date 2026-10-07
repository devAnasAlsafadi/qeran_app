import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/features/matchmaker/community/presentation/services/community_media_picker.dart';

class _MockImagePicker extends Mock implements ImagePicker {}

void main() {
  late _MockImagePicker images;
  late ImagePickerCommunityMediaPicker picker;
  setUpAll(() => registerFallbackValue(ImageSource.gallery));
  setUp(() {
    images = _MockImagePicker();
    picker = ImagePickerCommunityMediaPicker(images);
  });

  void single(ImageSource source, {XFile? answer, Object? error}) => when(
    () => images.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
      requestFullMetadata: false,
    ),
  ).thenAnswer((_) async => error == null ? answer : throw error);

  test('several from the gallery: the free slots as the limit, re-encoded '
      'at 1600 px and 85 (Q4), in her order', () async {
    when(
      () => images.pickMultiImage(
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
        limit: 3,
        requestFullMetadata: false,
      ),
    ).thenAnswer((_) async => [XFile('/b.jpg'), XFile('/a.jpg')]);

    expect(await picker.pickImages(limit: 3), ['/b.jpg', '/a.jpg']);
  });

  test('one slot left: a single pick (the multi-picker needs two)', () async {
    single(ImageSource.gallery, answer: XFile('/a.jpg'));

    expect(await picker.pickImages(limit: 1), ['/a.jpg']);
    verifyNever(
      () => images.pickMultiImage(
        maxWidth: any(named: 'maxWidth'),
        maxHeight: any(named: 'maxHeight'),
        imageQuality: any(named: 'imageQuality'),
        limit: any(named: 'limit'),
        requestFullMetadata: any(named: 'requestFullMetadata'),
      ),
    );
  });

  test('the camera: one photo, or null when she backs out', () async {
    single(ImageSource.camera, answer: XFile('/cam.jpg'));
    expect(await picker.captureImage(), '/cam.jpg');

    single(ImageSource.camera);
    expect(await picker.captureImage(), isNull);
  });

  test('a refused camera or library says which (S9)', () async {
    single(
      ImageSource.camera,
      error: PlatformException(code: 'camera_access_denied'),
    );
    await expectLater(
      picker.captureImage(),
      throwsA(
        isA<MediaAccessDenied>().having(
          (e) => e.access,
          'access',
          MediaAccess.camera,
        ),
      ),
    );

    single(
      ImageSource.gallery,
      error: PlatformException(code: 'photo_access_denied'),
    );
    await expectLater(
      picker.pickImages(limit: 1),
      throwsA(
        isA<MediaAccessDenied>().having(
          (e) => e.access,
          'access',
          MediaAccess.photos,
        ),
      ),
    );
  });

  test('any other platform error reads as backing out', () async {
    single(
      ImageSource.camera,
      error: PlatformException(code: 'no_available_camera'),
    );

    expect(await picker.captureImage(), isNull);
  });
}
