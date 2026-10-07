import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_progress_bar.dart';
import 'package:qeran/features/matchmaker/community/presentation/blocs/composer/post_draft_state.dart';
import 'package:qeran/features/matchmaker/community/presentation/widgets/composer/composer_draft_notice.dart';
import 'package:qeran/features/matchmaker/community/presentation/widgets/composer/publish_strip.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../../core/shipped_strings_rig.dart';

const _mb = 1024 * 1024;

final _copy = {
  'ar': (
    preparing: 'جارٍ تجهيز الفيديو… 42٪',
    cancel: 'إلغاء',
    tooLarge:
        'حجم هذا الفيديو 320 ميغابايت، وهو أكبر من الحد المسموح (300 '
        'ميغابايت). اختاري فيديو أقصر.',
  ),
  'en': (
    preparing: 'Preparing your video… 42%',
    cancel: 'Cancel',
    tooLarge:
        'This video is 320 MB, over the 300 MB limit. Choose a shorter video.',
  ),
};

/// D1's strip and Q3's video notice, in both languages. The whole flow on
/// the composer comes with sub-step 13, once a video can be published.
void main() {
  setUpAll(initShippedStrings);

  for (final MapEntry(key: language, value: t) in _copy.entries) {
    testWidgets('D1 [$language]: «${t.preparing}» over the bar; '
        '«${t.cancel}» stops it', (tester) async {
      var cancels = 0;
      await pumpShippedStrings(
        tester,
        Locale(language),
        settle: false,
        child: Scaffold(
          body: UploadStrip(
            progress: 0.42,
            onCancel: () => cancels++,
            label: LocaleKeys.matchmaker_community_preparing_video,
          ),
        ),
      );

      expect(find.text(t.preparing), findsOneWidget);
      expect(
        tester.widget<QeranProgressBar>(find.byType(QeranProgressBar)).value,
        0.42,
      );
      await tester.tap(find.text(t.cancel));
      expect(cancels, 1);
    });

    testWidgets('Q3 [$language]: the video\'s size and the limit, in MB', (
      tester,
    ) async {
      await pumpShippedStrings(
        tester,
        Locale(language),
        child: const Scaffold(
          body: ComposerDraftNotice(
            draft: PostDraftState(
              notice: VideoTooLarge(sizeBytes: 320 * _mb, maxBytes: 300 * _mb),
            ),
          ),
        ),
      );

      expect(find.text(t.tooLarge), findsOneWidget);
    });
  }
}
