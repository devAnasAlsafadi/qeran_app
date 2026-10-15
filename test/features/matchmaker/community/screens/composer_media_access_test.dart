import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/media/media_access.dart';
import 'package:qeran/features/community/domain/entities/community_config.dart';
import 'package:qeran/features/matchmaker/community/presentation/widgets/composer/composer_image_tile.dart';
import 'package:qeran/features/matchmaker/community/presentation/widgets/composer/composer_video_preview.dart';

import '../../../../core/media/media_access_rig.dart';
import '../../../../core/shipped_fonts_rig.dart';
import '../../../../core/shipped_strings_rig.dart';
import '../composer_rig.dart';

const _limits = CommunityConfig(
  postTextMaxLength: 2000,
  maxImagesPerPost: 10,
  allowedImageTypes: ['jpg', 'jpeg', 'png'],
  allowedVideoTypes: ['mp4', 'mov'],
  maxVideoDurationSeconds: 60,
  videoEnabled: true,
);

/// S9, run 11: her composer answers a refused camera or library as the
/// member's profile photos do, with the shared dialog and «فتح الإعدادات»
/// (it was a toast with no way to the settings). Nothing is added.
void main() {
  late ComposerHarness h;
  late FakeSettingsOpener settings;
  setUpAll(initShippedStrings);
  setUp(() {
    h = ComposerHarness()..configure(_limits);
    settings = registerFakeSettingsOpener();
  });
  tearDown(() => h.guidelines.dispose());

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  for (final lang in ['ar', 'en']) {
    testWidgets('$lang: «التقاط صورة» refused, the camera dialog', (
      tester,
    ) async {
      h.picker.refuses = const MediaAccessDenied(MediaAccess.camera);
      await startComposer(tester, h, locale: Locale(lang));

      await tapText(tester, lang == 'ar' ? 'صور' : 'Images');
      await tapText(tester, lang == 'ar' ? 'التقاط صورة' : 'Take a photo');

      expect(
        find.text(shipped(lang, 'media.camera_off_title')),
        findsOneWidget,
      );
      expect(find.text(shipped(lang, 'media.open_settings')), findsOneWidget);
      expect(find.byType(ComposerImageTile), findsNothing);
    });
  }

  testWidgets('the library refused (iOS): the photos dialog', (tester) async {
    h.picker.refuses = const MediaAccessDenied(MediaAccess.photos);
    await startComposer(tester, h);

    await tapText(tester, 'Images');
    await tapText(tester, 'Choose from gallery');

    expect(find.text(shipped('en', 'media.photos_off_title')), findsOneWidget);
    expect(find.byType(ComposerImageTile), findsNothing);
  });

  testWidgets('recording refused: the camera dialog, no video', (tester) async {
    h.picker.refuses = const MediaAccessDenied(MediaAccess.camera);
    await startComposer(tester, h);

    await tapText(tester, 'Video');
    await tapText(tester, 'Record a video');

    expect(find.text(shipped('en', 'media.camera_off_title')), findsOneWidget);
    expect(find.byType(ComposerVideoPreview), findsNothing);
  });

  testWidgets('«Open settings» opens the app\'s settings page', (tester) async {
    h.picker.refuses = const MediaAccessDenied(MediaAccess.camera);
    await startComposer(tester, h);
    await tapText(tester, 'Images');
    await tapText(tester, 'Take a photo');

    await tapText(tester, shipped('en', 'media.open_settings'));

    expect(settings.opened, 1);
    expect(find.text(shipped('en', 'media.camera_off_title')), findsNothing);
  });
}
