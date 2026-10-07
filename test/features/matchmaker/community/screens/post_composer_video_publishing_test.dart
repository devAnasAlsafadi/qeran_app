import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/domain/entities/community_config.dart';
import 'package:qeran/features/community/domain/entities/community_post.dart';
import 'package:qeran/features/community/domain/entities/media_refusal.dart';
import 'package:qeran/features/community/domain/entities/media_upload_outcome.dart';
import 'package:qeran/features/community/domain/entities/post_publish_outcome.dart';
import 'package:qeran/features/matchmaker/community/presentation/widgets/composer/composer_video_preview.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../../../community/fixtures/community_post_fixtures.dart';
import '../composer_rig.dart';
import '../publishing_rig.dart';

const _ar = Locale('ar');
const _en = Locale('en');

final _copy = {
  _ar: (
    video: 'فيديو',
    gallery: 'اختيار من المعرض',
    publish: 'نشر',
    preparing: 'جارٍ تجهيز الفيديو… 50٪',
    uploading: 'جارٍ رفع المنشور… 50٪',
    cancel: 'إلغاء',
    unavailable: 'خدمة الفيديو غير متاحة حالياً. حاولي مرة أخرى بعد قليل.',
    retry: 'إعادة المحاولة',
  ),
  _en: (
    video: 'Video',
    gallery: 'Choose from gallery',
    publish: 'Publish',
    preparing: 'Preparing your video… 50%',
    uploading: 'Uploading your post… 50%',
    cancel: 'Cancel',
    unavailable:
        'The video service is unavailable right now. Try again in a moment.',
    retry: 'Retry',
  ),
};

const _limits = CommunityConfig(
  postTextMaxLength: 2000,
  allowedVideoTypes: ['mp4', 'mov'],
  maxVideoDurationSeconds: 60,
  maxVideoSizeBytes: 314572800,
  videoEnabled: true,
);

/// D1, D2, D4 and BA-A6 on her composer, in both languages.
void main() {
  late ComposerHarness h;
  setUpAll(initShippedStrings);
  setUp(() {
    h = ComposerHarness()..configure(_limits);
    h.picker.video = 'clip.mp4';
  });
  tearDown(() => h.guidelines.dispose());

  Future<void> publishWithVideo(WidgetTester tester, Locale locale) async {
    final t = _copy[locale]!;
    await startComposer(tester, h, locale: locale);
    await tester.enterText(find.byType(TextField), 'إرشاد');
    await tester.tap(find.text(t.video).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.gallery));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.publish));
    await frames(tester);
  }

  for (final locale in [_ar, _en]) {
    final t = _copy[locale]!;

    testWidgets('D1, D2 [${locale.languageCode}]: «${t.preparing}», then '
        '«${t.uploading}», each with «${t.cancel}»; made Processing, it '
        'closes with her post (D4)', (tester) async {
      final compressing = h.compressor.hold = Completer();
      final uploading = h.publishing.video.hold = Completer();
      h.publishes(Right(PostPublished(testPost(id: 31, status: _processing))));
      await publishWithVideo(tester, locale);

      expect(find.text(t.preparing), findsOneWidget);
      expect(find.text(t.cancel), findsOneWidget);
      compressing.complete();
      await frames(tester);
      expect(find.text(t.uploading), findsOneWidget);
      expect(find.text(t.cancel), findsOneWidget);

      uploading.complete();
      await tester.pumpAndSettle();
      expect(h.result?.status, _processing);
      expect(h.publishing.lastVideoId(), 'v-1');
    });

    testWidgets('BA-A6 [${locale.languageCode}]: «${t.unavailable}» with '
        '«${t.retry}», no bar; Retry publishes', (tester) async {
      h.publishing.video.grants(const Right(MediaVideoUnavailable()));
      h.publishes(Right(PostPublished(testPost(id: 31, status: _processing))));
      await publishWithVideo(tester, locale);

      expect(find.text(t.unavailable), findsOneWidget);
      expect(find.byType(ComposerVideoPreview), findsOneWidget);
      h.publishing.video.grants();
      await tester.tap(find.text(t.retry));
      await tester.pumpAndSettle();

      expect(h.result?.id, 31);
    });
  }

  testWidgets('«Cancel» while it compresses: the draft is hers again, her '
      'video still there', (tester) async {
    h.compressor.hold = Completer();
    await publishWithVideo(tester, _en);

    await tester.tap(find.text('Cancel'));
    await frames(tester);

    expect(find.text('Preparing your video… 50%'), findsNothing);
    expect(find.byType(ComposerVideoPreview), findsOneWidget);
    expect(h.sentIds, isEmpty);
  });

  testWidgets('the server finds it too long (MEDIA_TOO_LONG on 6.8): BA-A9, '
      'and the video leaves the draft', (tester) async {
    h.publishing.video.grants(
      const Right(MediaUploadRefused(MediaRefusal.tooLong)),
    );
    await publishWithVideo(tester, _en);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'This video is 0:30, longer than the 1:00 limit. Choose a shorter '
        'video or trim it first.',
      ),
      findsOneWidget,
    );
    expect(find.byType(ComposerVideoPreview), findsNothing);
  });
}

const _processing = CommunityPostStatus.processing;
