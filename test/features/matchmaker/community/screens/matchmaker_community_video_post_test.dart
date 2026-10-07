import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/domain/entities/community_config.dart';
import 'package:qeran/features/community/domain/entities/community_post.dart';
import 'package:qeran/features/community/domain/entities/post_publish_outcome.dart';
import 'package:qeran/features/matchmaker/community/presentation/screens/matchmaker_community_screen.dart';
import 'package:qeran/features/matchmaker/community/presentation/screens/post_composer_screen.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../../../community/fixtures/community_post_fixtures.dart';
import '../community_screen_rig.dart';
import '../composer_rig.dart';

final _copy = {
  'ar': (
    newPost: 'منشور جديد',
    video: 'فيديو',
    gallery: 'اختيار من المعرض',
    publish: 'نشر',
    toast: 'تم رفع المنشور. يظهر للأعضاء بعد اكتمال معالجة الفيديو.',
  ),
  'en': (
    newPost: 'New post',
    video: 'Video',
    gallery: 'Choose from gallery',
    publish: 'Publish',
    toast: 'Uploaded. Members will see it once the video finishes processing.',
  ),
};

/// D4: her video post made, Processing — she lands on «منشوراتي» with it
/// first, and the toast says members see it once it's processed.
void main() {
  late CommunityScreenHarness h;
  late ComposerHarness composer;
  setUpAll(initShippedStrings);
  setUp(() {
    h = CommunityScreenHarness();
    h.all.page(1, [testPost(id: 1, text: englishText)]);
    composer = ComposerHarness()
      ..configure(
        const CommunityConfig(
          postTextMaxLength: 2000,
          maxVideoDurationSeconds: 60,
          videoEnabled: true,
        ),
      );
    composer.picker.video = 'clip.mp4';
  });
  tearDown(() => h.dispose());

  for (final MapEntry(key: language, value: t) in _copy.entries) {
    testWidgets('D4 [$language]: «${t.toast}», the Processing card first', (
      tester,
    ) async {
      const processing = CommunityPostStatus.processing;
      composer.publishes(
        Right(PostPublished(testPost(id: 31, status: processing))),
      );
      h.myPage(1, [
        testPost(id: 31, text: 'Just now', status: processing),
        testPost(id: 5, text: 'Mine'),
      ]);
      await pumpHerApp(
        tester,
        const MatchmakerCommunityScreen(),
        locale: Locale(language),
      );

      await tester.tap(find.text(t.newPost));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'إرشاد');
      await tester.tap(find.text(t.video).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.gallery));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.publish));
      await tester.pumpAndSettle();

      expect(find.byType(PostComposerScreen), findsNothing);
      expect(find.text(t.toast), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Just now')).dy,
        lessThan(tester.getTopLeft(find.text('Mine')).dy),
      );
      await tester.pump(const Duration(seconds: 5));
    });
  }
}
