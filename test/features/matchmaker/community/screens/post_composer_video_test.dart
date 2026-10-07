import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/features/community/domain/entities/community_config.dart';
import 'package:qeran/features/matchmaker/community/presentation/widgets/composer/composer_video_preview.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../composer_media_fakes.dart';
import '../composer_rig.dart';

const _ar = Locale('ar');
const _en = Locale('en');

final _copy = {
  _ar: (
    images: 'صور',
    video: 'فيديو',
    either: 'صور متعددة أو فيديو واحد',
    imagesOnly: 'يمكن إضافة صور فقط حالياً',
    noImages: 'لا يمكن إضافة صور مع الفيديو',
    noVideo: 'لا يمكن إضافة فيديو مع الصور',
    sheet: 'إضافة فيديو',
    gallery: 'اختيار من المعرض',
    record: 'تصوير فيديو',
    note:
        'المدة القصوى دقيقة واحدة، وتُفحص عند التصوير والاختيار. يُضغط '
        'الفيديو على الهاتف قبل رفعه.',
    max: 'الحد الأقصى 1:00',
    tooLong:
        'مدة هذا الفيديو 1:24، وهي أطول من الحد المسموح (1:00). اختاري فيديو '
        'أقصر أو قصّيه أولاً.',
    unsupported:
        'نوع هذا الملف غير مدعوم. استخدمي صور JPG أو PNG، أو فيديو '
        'MP4 أو MOV.',
  ),
  _en: (
    images: 'Images',
    video: 'Video',
    either: 'Several images or one video',
    imagesOnly: 'Only images can be added for now',
    noImages: 'Images can’t be added with a video',
    noVideo: 'Video can’t be added with images',
    sheet: 'Add a video',
    gallery: 'Choose from gallery',
    record: 'Record a video',
    note:
        'Up to 1 minute, checked when recording and when picking. The video '
        'is compressed on the phone before upload.',
    max: 'Max 1:00',
    tooLong:
        'This video is 1:24, longer than the 1:00 limit. Choose a shorter '
        'video or trim it first.',
    unsupported:
        'This file type isn’t supported. Use JPG or PNG images, or a video in '
        'MP4 or MOV.',
  ),
};

const _limits = CommunityConfig(
  postTextMaxLength: 2000,
  maxImagesPerPost: 10,
  allowedImageTypes: ['jpg', 'jpeg', 'png'],
  allowedVideoTypes: ['mp4', 'mov'],
  maxVideoDurationSeconds: 60,
  videoEnabled: true,
);

void main() {
  late ComposerHarness h;
  setUpAll(initShippedStrings);
  setUp(() => h = ComposerHarness()..configure(_limits));
  tearDown(() => h.guidelines.dispose());

  Future<void> tapAndSettle(WidgetTester tester, String text) async {
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  double opacityOf(WidgetTester tester, String label) => tester
      .widget<Opacity>(
        find
            .ancestor(of: find.text(label).last, matching: find.byType(Opacity))
            .first,
      )
      .opacity;

  for (final locale in [_ar, _en]) {
    final t = _copy[locale]!;

    testWidgets('C1, BA-A8 [${locale.languageCode}]: «${t.images}», '
        '«${t.video}» and «${t.either}»; the video sheet with its note; '
        'recording is told the cap', (tester) async {
      await startComposer(tester, h, locale: locale);
      expect(find.text(t.either), findsOneWidget);
      // The boards' outlined glyphs (sweep 18.9).
      expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
      expect(find.byIcon(Icons.videocam_outlined), findsOneWidget);

      await tapAndSettle(tester, t.video);
      expect(find.text(t.sheet), findsOneWidget);
      expect(find.text(t.gallery), findsOneWidget);
      expect(find.byIcon(Icons.video_library_outlined), findsOneWidget);
      expect(find.text(t.note), findsOneWidget);
      await tapAndSettle(tester, t.record);

      expect(h.picker.caps, [const Duration(seconds: 60)]);
    });

    testWidgets('C6 [${locale.languageCode}]: her video — «${t.max}», the '
        'preview, «${t.images}» dimmed with «${t.noImages}»', (tester) async {
      h.picker.video = 'clip.mp4';
      await startComposer(tester, h, locale: locale);
      await tapAndSettle(tester, t.video);
      await tapAndSettle(tester, t.gallery);

      expect(find.byType(ComposerVideoPreview), findsOneWidget);
      expect(find.text(t.max), findsOneWidget);
      expect(find.text('0:30'), findsOneWidget);
      expect(find.text(t.noImages), findsOneWidget);
      expect(opacityOf(tester, t.images), 0.4);
      expect(opacityOf(tester, t.video), 0.4);
    });

    testWidgets('BA-A9, C10 [${locale.languageCode}]: too long or the wrong '
        'type — not attached, and why', (tester) async {
      h.compressor.infos['long.mp4'] = clip(seconds: 84);
      h.inspector.videos['x.webm'] = null;
      await startComposer(tester, h, locale: locale);

      h.picker.video = 'long.mp4';
      await tapAndSettle(tester, t.video);
      await tapAndSettle(tester, t.gallery);
      expect(find.text(t.tooLong), findsOneWidget);

      h.picker.video = 'x.webm';
      await tapAndSettle(tester, t.video);
      await tapAndSettle(tester, t.gallery);
      expect(find.text(t.unsupported), findsOneWidget);
      expect(find.byType(ComposerVideoPreview), findsNothing);
    });

    testWidgets('BA-A4, A5 [${locale.languageCode}]: video off on the '
        'server — no «${t.video}», and «${t.imagesOnly}»', (tester) async {
      h.configure(const CommunityConfig(postTextMaxLength: 2000));
      await startComposer(tester, h, locale: locale);

      expect(find.text(t.video), findsNothing);
      expect(find.text(t.imagesOnly), findsOneWidget);
    });
  }

  testWidgets('with images: «Video» dimmed, and why', (tester) async {
    h.picker.gallery = ['a.jpg'];
    await startComposer(tester, h);
    await tapAndSettle(tester, 'Images');
    await tapAndSettle(tester, 'Choose from gallery');

    expect(find.text('Video can’t be added with images'), findsOneWidget);
    expect(opacityOf(tester, 'Video'), 0.4);
  });

  testWidgets('with text and a video, «Publish» is on; × on the video removes '
      'it', (tester) async {
    h.picker.video = 'clip.mp4';
    await startComposer(tester, h);
    await tester.enterText(find.byType(TextField), 'إرشاد');
    await tapAndSettle(tester, 'Video');
    await tapAndSettle(tester, 'Choose from gallery');

    bool publishOn() =>
        tester
            .widget<QeranButton>(find.widgetWithText(QeranButton, 'Publish'))
            .onPressed !=
        null;
    expect(publishOn(), isTrue);

    await tester.tap(find.bySemanticsLabel('Remove video'));
    await tester.pumpAndSettle();

    expect(publishOn(), isTrue);
    expect(find.byType(ComposerVideoPreview), findsNothing);
    expect(find.text('Several images or one video'), findsOneWidget);
  });
}
