import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/design_system/widgets/qeran_confirm_dialog.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/profile/presentation/screens/photo_manager/widgets/photo_picker_bottom_sheet.dart';

import '../../../../core/media/media_access_rig.dart';
import '../../../../core/shipped_fonts_rig.dart';
import '../../../../core/shipped_strings_rig.dart';

class _MockImagePicker extends Mock implements ImagePicker {}

/// Anas's hand test (run 11): a new member adds a photo later, picks the
/// camera and refuses it. The sheet has closed by then, so the pick runs on
/// the photo manager: a refusal gets the settings dialog, backing out stays
/// silent, a photo reaches the cubit.
void main() {
  late _MockImagePicker images;
  late FakeSettingsOpener settings;
  late List<String> picked;

  setUpAll(initShippedStrings);
  setUp(() {
    images = _MockImagePicker();
    settings = registerFakeSettingsOpener();
    picked = [];
  });
  tearDown(sl.reset);

  void answer(ImageSource source, {String? path, String? refusal}) =>
      when(
        () => images.pickImage(
          source: source,
          imageQuality: 85,
          requestFullMetadata: false,
        ),
      ).thenAnswer(
        (_) async => refusal == null
            ? (path == null ? null : XFile(path))
            : throw PlatformException(code: refusal),
      );

  /// Opens the sheet in Arabic and taps [option] («الكاميرا» or «المعرض»).
  Future<void> choose(WidgetTester tester, String option) async {
    final context = await pumpShippedStrings(tester, const Locale('ar'));
    PhotoPickerBottomSheet.show(
      context,
      onImagePicked: picked.add,
      picker: images,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(shipped('ar', option)));
    await tester.pumpAndSettle();
  }

  testWidgets('the camera refused: the camera dialog, nothing added', (
    tester,
  ) async {
    answer(ImageSource.camera, refusal: 'camera_access_denied');

    await choose(tester, 'auth.photo_camera');

    expect(find.byType(PhotoPickerBottomSheet), findsNothing);
    expect(find.text(shipped('ar', 'media.camera_off_title')), findsOneWidget);
    expect(picked, isEmpty);
  });

  testWidgets('«فتح الإعدادات» from there opens the app\'s settings', (
    tester,
  ) async {
    answer(ImageSource.camera, refusal: 'camera_access_denied');
    await choose(tester, 'auth.photo_camera');

    await tester.tap(find.text(shipped('ar', 'media.open_settings')));
    await tester.pumpAndSettle();

    expect(settings.opened, 1);
  });

  testWidgets('the library refused (iOS): the photos dialog', (tester) async {
    answer(ImageSource.gallery, refusal: 'photo_access_denied');

    await choose(tester, 'auth.photo_gallery');

    expect(find.text(shipped('ar', 'media.photos_off_title')), findsOneWidget);
    expect(picked, isEmpty);
  });

  testWidgets('backing out of the picker: no dialog, nothing added', (
    tester,
  ) async {
    answer(ImageSource.camera);

    await choose(tester, 'auth.photo_camera');

    expect(find.byType(QeranConfirmDialog), findsNothing);
    expect(picked, isEmpty);
  });

  testWidgets('a photo: added, no dialog', (tester) async {
    answer(ImageSource.gallery, path: '/photo.jpg');

    await choose(tester, 'auth.photo_gallery');

    expect(picked, ['/photo.jpg']);
    expect(find.byType(QeranConfirmDialog), findsNothing);
  });

  testWidgets('closing the sheet: the picker never opens', (tester) async {
    final context = await pumpShippedStrings(tester, const Locale('ar'));
    PhotoPickerBottomSheet.show(
      context,
      onImagePicked: picked.add,
      picker: images,
    );
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.byType(PhotoPickerBottomSheet), findsNothing);
    verifyZeroInteractions(images);
    expect(picked, isEmpty);
  });
}
