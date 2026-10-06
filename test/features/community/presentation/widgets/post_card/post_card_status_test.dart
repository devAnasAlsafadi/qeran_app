import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/domain/entities/community_media.dart';
import 'package:qeran/features/community/domain/entities/community_post.dart';
import 'package:qeran/features/community/presentation/widgets/video/video_layers.dart';

import '../../../../../core/shipped_strings_rig.dart';
import '../../../fixtures/community_post_fixtures.dart';
import 'post_card_rig.dart';

const _ar = Locale('ar');
const _en = Locale('en');

final _copy = {
  _ar: (
    processing: 'قيد المعالجة · يظهر للأعضاء عند اكتماله',
    failed: 'تعذّرت معالجة الفيديو',
    failedBody: 'لا يظهر للأعضاء. احذفيه وانشريه من جديد.',
    delete: 'حذف',
    like: 'إعجاب',
  ),
  _en: (
    processing: 'Processing · shown to members when ready',
    failed: 'Couldn’t process the video',
    failedBody: 'Members can’t see it. Delete it and publish again.',
    delete: 'Delete',
    like: 'Like',
  ),
};

/// Her video as the server sends it while it encodes: no link, and — as
/// measured on post 5 — no size (0 × 0) unless [width] and [height] say.
CommunityPost _hers(
  CommunityPostStatus status, {
  int width = 0,
  int height = 0,
}) => testPost(
  id: 5,
  canDelete: true,
  status: status,
  media: CommunitySingleVideo(
    testVideo(url: null, posterUrl: null, width: width, height: height),
  ),
);

double _frameRatio(WidgetTester tester) =>
    tester.widget<AspectRatio>(find.byType(AspectRatio).first).aspectRatio;

void main() {
  setUpAll(initShippedStrings);

  for (final locale in [_ar, _en]) {
    final t = _copy[locale]!;

    testWidgets('D4 [${locale.languageCode}]: processing — the gold strip, a '
        '16:9 frame with no play disc, the footer', (tester) async {
      await pumpCard(
        tester,
        _hers(CommunityPostStatus.processing),
        locale: locale,
      );

      expect(find.text(t.processing), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
      expect(_frameRatio(tester), closeTo(16 / 9, 0.001));
      expect(find.byType(VideoPlayDisc), findsNothing);
      expect(find.text(t.like), findsOneWidget);
    });

    testWidgets('BA-A1 [${locale.languageCode}]: failed — why, her Delete, '
        'the frame says so, and no footer', (tester) async {
      await pumpCard(tester, _hers(CommunityPostStatus.failed), locale: locale);

      expect(find.text(t.failed), findsNWidgets(2));
      expect(find.text(t.failedBody), findsOneWidget);
      expect(find.text(t.delete), findsOneWidget);
      expect(find.byIcon(Icons.videocam_off_rounded), findsOneWidget);
      expect(find.byType(VideoPlayDisc), findsNothing);
      expect(find.text(t.like), findsNothing);
    });
  }

  testWidgets('Q5: a size the server does send while processing shapes the '
      'frame', (tester) async {
    await pumpCard(
      tester,
      _hers(CommunityPostStatus.processing, width: 1080, height: 1080),
    );

    expect(_frameRatio(tester), closeTo(1, 0.001));
  });

  testWidgets('a published post has no strip', (tester) async {
    await pumpCard(tester, _hers(CommunityPostStatus.published));

    expect(find.text(_copy[_en]!.processing), findsNothing);
    expect(find.text(_copy[_en]!.failed), findsNothing);
  });
}
